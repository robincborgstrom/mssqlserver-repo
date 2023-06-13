SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_AddInvoice_partialPay]  
(    
 @customer_id bigint,    
 @description Varchar(255),    
 @job_title varchar(40),  
 @invoice_reference Varchar(255),    
 @billing_date Date,    
 @due_date Date,    
 @overdue int,    
 @total_sum numeric(10,2),    
 @instant_payment varchar(50),    
 @status int,
 @sended_by varchar(200)=NULL,
 @uuid uniqueidentifier,  
 @invoice_items AS dbo.TabledInvoice_itemsinfo READONLY,  
 @invoice_id bigint output,    
 @customersid bigint output,
 @invoice_uuid uniqueidentifier output,
 @building_service bit,
 @invoice_price_selection bit,
 @delivery_method varchar(200),
 @invoice_lang varchar(50) = null,
  --Partial Invoice
 @base_invoice_id bigint = null,
 @base_uuid uniqueidentifier = null,
 @notes varchar(5000) = null,
 @partial_amount_received [decimal] (10,2) = 0,
 @duedatefee [decimal] (10,2) = 0,
 @partialpayfee [decimal] (10,2) = 0,
 @interestfee [decimal] (10,2) = 0
 --Partial Invoice
 )    
AS     
BEGIN     
BEGIN TRY    
BEGIN TRANSACTION  

DECLARE @originalInvoiceUuid uniqueidentifier
SET @originalInvoiceUuid = @uuid

--AdminFee
IF (@base_uuid IS NOT NULL)
BEGIN
	SET @uuid = (select uuid from user_info where roleid = 3)
END

DECLARE @newinvoice_id bigINT  
DECLARE @userid bigINT
DECLARE @sendedUserId bigINT
		
set @sendedUserId = (select user_id from user_info where email = @sended_by and deleted = 0)

--Partial Invoice
DECLARE @interestfee_sum decimal(10,2)
SET @interestfee_sum = 0
DECLARE @original_invoice_sum decimal(10,2)
SET @original_invoice_sum = @total_sum
DECLARE @old_due_date Date 
IF(@base_invoice_id IS NOT NULL AND @base_uuid IS NULL)
BEGIN
 Exec [sp_CalculateInvoicePartialInfo] @base_invoice_id = @base_invoice_id,
 @uuid = @uuid, @partial_amount_received = @partial_amount_received,
 @duedatefee = @duedatefee, @partialpayfee = @partialpayfee, 
 @interestfee = @interestfee, @due_date = @due_date,
 @total_sum = @original_invoice_sum output, 
 @interestfee_sum = @interestfee_sum output, 
 @old_due_date = @old_due_date output
END
ELSE IF(@base_invoice_id IS NOT NULL AND @base_uuid IS NOT NULL)
BEGIN
 Exec [sp_CalculateAdminFeeInvoicePartialInfo] @base_invoice_id = @base_invoice_id,
 @base_uuid = @base_uuid,
 @uuid = @uuid, @partial_amount_received = @partial_amount_received,
 @duedatefee = @duedatefee, @partialpayfee = @partialpayfee, 
 @interestfee = @interestfee, @due_date = @due_date,
 @total_sum = @original_invoice_sum output, 
 @interestfee_sum = @interestfee_sum output, 
 @old_due_date = @old_due_date output
END
--Partial Invoice  

IF NOT EXISTS (SELECT * FROM invoice)  
begin   
	SET @newinvoice_id=111 
end   
ELSE  
SET @newinvoice_id=(SELECT MAX(i.invoice_id)+1   
            FROM invoice i)  
 
 INSERT INTO Invoice  
 ([invoice_id],  
  [customer_id],    
  [description],    
  [job_title],    
  [invoice_reference],    
  [billing_date],    
  [due_date],    
  [overdue],    
  [total_sum],    
  [instant_payment],    
  [status],  
  [uuid],  
  [building_service],
  [invoice_price_selection],
  [sended_by] ,
  [delivery_method],
  [invoice_lang]
 )VALUES  
 (    
  @newinvoice_id,  
  @customer_id,  
  @description,    
  @job_title,  
  @invoice_reference,  
  @billing_date ,    
  @due_date ,    
  @overdue,
  --@total_sum,
  --Partial Invoice
  @original_invoice_sum,
  --Partial Invoice
  @instant_payment,    
  @status,  
  @uuid,  
  @building_service,
  @invoice_price_selection,
  @sendedUserId,
  @delivery_method,
  @invoice_lang
  );  

--Partial Invoice
IF(@base_invoice_id IS NOT NULL AND @base_uuid IS NULL)
BEGIN
Exec [sp_AddInvoicePartialInfo] @base_invoice_id = @base_invoice_id,
@uuid = @uuid,
@newinvoice_id = @newinvoice_id ,
@notes = @notes,
@due_date = @due_date, 
@partial_amount_received = @partial_amount_received,
@duedatefee = @duedatefee ,
@partialpayfee = @partialpayfee,
@partialinterestfee = @interestfee_sum,
@old_due_date = @old_due_date

Update Invoice set notes = @notes where invoice_id = @newinvoice_id and uuid = @originalInvoiceUuid  

END
ELSE IF(@base_invoice_id IS NOT NULL AND @base_uuid IS NOT NULL)
BEGIN
  Insert into Invoice_Partial_Info(invoice_id, uuid, duedatefee, partialpayfee, base_invoice_id, last_due_date, partialinterestfee, original_invoice_id,
  base_uuid)
  (Select @newinvoice_id, @uuid, @duedatefee, @partialpayfee, @base_invoice_id, @old_due_date, @interestfee_sum, @base_invoice_id, @base_uuid  from Invoice where            
  invoice_id = @base_invoice_id and uuid = @base_uuid)

  Update Invoice set notes=@notes, due_date = DATEADD(day, 7, Getdate()) where invoice_id = @newinvoice_id
  and uuid = @uuid
  
  Update Invoice set due_date = @due_date where invoice_id = @base_invoice_id
  and uuid = @originalInvoiceUuid

  IF(@partial_amount_received > 0)
  BEGIN
  Update Invoice set partial_amount_received = @partial_amount_received, 
  status = 15, invoicepaid = 1, payment_received_date = GETDATE()  
  where invoice_id = @base_invoice_id and uuid = @base_uuid

  Update Invoice set admin_fee_status = 'processing'
  where invoice_id = @base_invoice_id and uuid = @base_uuid
  and partial_amount_received > total_sum
  END  
END
--Partial Invoice

  IF(@base_invoice_id IS NOT NULL AND @base_uuid IS NOT NULL)
  BEGIN
   INSERT INTO Invoice_items (invoice_item_id,invoice_id,uuid,description,start_date,end_date,quantity,unit,quantity_price,vat_percent,vat,sum_tax_free,invoice_expense_id,invoice_allowance_id)  
   SELECT invoice_item_id, @newinvoice_id,@uuid,description, start_date,end_date,quantity,unit, @original_invoice_sum, vat_percent,vat,@original_invoice_sum,invoice_expense_id,invoice_allowance_id FROM @invoice_items
  END
  ELSE
  BEGIN  
   INSERT INTO Invoice_items (invoice_item_id,invoice_id,uuid,description,start_date,end_date,quantity,unit,quantity_price,vat_percent,vat,sum_tax_free,invoice_expense_id,invoice_allowance_id)  
   SELECT invoice_item_id, @newinvoice_id,@uuid,description, start_date,end_date,quantity,unit,quantity_price,vat_percent,vat,sum_tax_free,invoice_expense_id,invoice_allowance_id FROM @invoice_items  
  END

   update invoice_expense set added_to_invoice =1, attach_option = 'add_to_invoice', invoice_id=@newinvoice_id  
   where invoice_expense_id in (select invoice_expense_id from @invoice_items) and uuid=@uuid  
  
   update invoice_allowance set added_to_invoice =1, attach_option = 'add_to_invoice', invoice_id=@newinvoice_id  
   where id in (select invoice_allowance_id from @invoice_items) and uuid=@uuid 

  
   select @newinvoice_id as invoice_id,@customer_id as customersid,@uuid as invoice_uuid  
	
	
	 
COMMIT  
 END TRY  
    BEGIN CATCH  
  IF @@TRANCOUNT > 0  
  BEGIN  
  ROLLBACK  
  exec dbo.sp_KvtErrorLogging   
  END;  
  THROW;  
 END CATCH    
END
GO
