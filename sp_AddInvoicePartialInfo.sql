SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_AddInvoicePartialInfo]    
(
 @base_invoice_id bigint = null,
 @uuid uniqueidentifier,
 @newinvoice_id bigINT,
 @newpartial_invoice_id bigINT, 
 @notes varchar(5000) = null,
 @due_date Date, 
 @partial_amount_received [decimal] (10,2) = 0,
 @duedatefee [decimal] (10,2) = 0,
 @partialpayfee [decimal] (10,2) = 0,
 @partialinterestfee [decimal] (10,2) = 0,
 @old_due_date Date
)  
AS       
BEGIN       
BEGIN TRY      
BEGIN TRANSACTION

 -- DECLARE @original_invoice_id bigint

 -- IF EXISTS (SELECT * FROM Invoice_Partial_Info WHERE invoice_id = @base_invoice_id and uuid = @uuid)
	--SET @original_invoice_id= (SELECT TOP 1 original_invoice_id FROM Invoice_Partial_Info WHERE invoice_id = @base_invoice_id and uuid = @uuid ORDER BY original_invoice_id)	
 -- ELSE
 --   SET @original_invoice_id=@base_invoice_id 

 -- Insert into Invoice_Partial_Info(invoice_id, partial_invoice_id, uuid, duedatefee, partialpayfee, base_invoice_id, last_due_date, partialinterestfee, original_invoice_id)
 -- (Select @newinvoice_id, @newpartial_invoice_id, uuid, @duedatefee, @partialpayfee, @base_invoice_id, @old_due_date, @partialinterestfee, @original_invoice_id  from Invoice where            
 -- invoice_id = @base_invoice_id and uuid = @uuid and partial_invoice_id = @newpartial_invoice_id)
  
  --Update Invoice set billing_date = GETDATE() where invoice_id = @newinvoice_id and uuid = @uuid

 --Invoice Status 13-Modified, 14-Inactive, 15-PartialPay
 IF(@partial_amount_received > 0) 
  BEGIN  
  Update Invoice set partial_amount_received = @partial_amount_received, status = 15,  
  invoicepaid = 1, payment_received_date = GETDATE()  
  where invoice_id = @base_invoice_id and uuid = @uuid and partial_invoice_id = @newpartial_invoice_id - 1

  Update Invoice set admin_fee_status = 'processing'
  where invoice_id = @base_invoice_id and uuid = @uuid and partial_invoice_id = @newpartial_invoice_id - 1
  and partial_amount_received > total_sum
  END
  ELSE
   BEGIN    
	 Update Invoice set status = 14 where invoice_id = @base_invoice_id and 
	 uuid = @uuid and partial_invoice_id = @newpartial_invoice_id - 1 and deleted = 0	 
   END
    
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


-------------------------------------------------------------------------------------------------------------------

/****** Object:  StoredProcedure [dbo].[sp_AddInvoiceTotalInformation]    Script Date: 02/06/2023 12.45.34 ******/
SET ANSI_NULLS ON
GO
