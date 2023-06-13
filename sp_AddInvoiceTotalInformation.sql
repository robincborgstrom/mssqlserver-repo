SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_AddInvoiceTotalInformation]
(
 @country varchar(255),  
 @company_name varchar(255),  
 @business_id varchar(255),  
 @person_to_contact varchar(255),  
 @person_to_contact_email varchar(255),  
 @delivery_address varchar(255),  
 @zip_code varchar(255),  
 @city varchar(255),  
 @web_invoice varchar(255),  
 @delivery_method varchar(255), 
 @description varchar(255),  
 @job_title varchar(40),
 @invoice_reference varchar(255),  
 @billing_date date,  
 @due_date date,  
 @overdue int,  
 @total_sum numeric(10,2),  
 @instant_payment varchar(50),  
 @status int,
 @Invoice_items AS dbo.TabledInvoice_itemsinfo_refactored READONLY, 
 @uuid uniqueidentifier,
 @finvoice_operator varchar(100),
 @invoice_id bigint OUTPUT, 
 @customersid bigint OUTPUT,
 @invoice_uuid uniqueidentifier OUTPUT,
 @partial_invoice_id bigint OUTPUT,
 @building_service bit,
 @invoice_price_selection bit,
 @person_to_quick_pay_email varchar(200), 
 @sended_by varchar(200)=NULL,
 @customer_type varchar(255),
 @invoice_lang varchar(50) = null,
   --Partial Invoice
 @base_invoice_id bigint = null,
 @base_partial_invoice_id bigint = null,
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

DECLARE @customerID bigint   
DECLARE @newinvoiceid bigint
DECLARE @newpartial_invoice_id bigint



  Exec [sp_CustomerExist]  @person_to_contact_email =@person_to_contact_email ,
						 @uuid=@uuid,@company_name=@company_name, @customer_id=@customerID output
  

	IF(@customerID IS NULL) 
		Exec dbo.sp_AddCustomer 
			@country,@company_name,@business_id,@person_to_contact,
			@person_to_contact_email,@delivery_address,@zip_code ,  
			@city ,@web_invoice ,@delivery_method,@uuid,@finvoice_operator,@invoice_price_selection,@person_to_quick_pay_email,@customer_type
    Else
		UPDATE CUSTOMERS SET 
        [country]=@country,
        [company_name]=@company_name,
		[business_id]=@business_id,
		[person_to_contact]=@person_to_contact ,
		[person_to_contact_email]=@person_to_contact_email,
		[delivery_address]=@delivery_address,
		[zip_code]= @zip_code, 
		[city]=@city,
		[web_invoice]=@web_invoice,
		[finvoice_operator]=@finvoice_operator,
		[delivery_method]=@delivery_method,
		[invoice_price_selection]=@invoice_price_selection,
		[uuid]=@uuid,
		[person_to_quick_pay_email]=@person_to_quick_pay_email,
		[customer_type]=@customer_type
	WHERE customer_id=@CustomerID		 	
  
		Exec [sp_CustomerExist]  @person_to_contact_email =@person_to_contact_email ,
						 @uuid=@uuid,@company_name =@company_name , @customer_id=@customerID output

		Exec dbo.sp_AddInvoice
		@CustomerID,@description,@job_title,
		@invoice_reference,@billing_date ,@due_date ,@overdue,  
		@total_sum,@instant_payment,@status,@sended_by,
		--@uuid,
		@originalInvoiceUuid,
		@invoice_items,
		@newinvoiceid output,		
		@customersid output,
		@invoice_uuid output,
		@newpartial_invoice_id output,
		@building_service=@building_service,
		@invoice_price_selection=@invoice_price_selection,@delivery_method=@delivery_method,@invoice_lang=@invoice_lang,
		--Partial Invoice
        @base_invoice_id=@base_invoice_id,
		@base_partial_invoice_id=@base_partial_invoice_id,
		@base_uuid=@base_uuid,
		@notes=@notes,
		@partial_amount_received=@partial_amount_received,
		@duedatefee=@duedatefee,@partialpayfee=@partialpayfee,
		@interestfee=@interestfee
        --Partial Invoice  
		
		DECLARE @custID bigint   
		DECLARE @invoiceid bigint   

		select top(1) @invoiceid=invoice_id, @custID=customer_id from invoice where uuid=@uuid order by created desc
	
	IF NOT EXISTS (SELECT * FROM invoice_customer_info where invoice_id = @invoiceid 
	--and customer_id = @custID
	)
	
    BEGIN   

    INSERT INTO invoice_customer_info (invoice_id,uuid,customer_id,country,
	company_name,business_id,person_to_contact,person_to_contact_email,person_to_quick_pay_email,
	delivery_address,zip_code,city,web_invoice,delivery_method,finvoice_operator,customer_type)
	values( @invoiceid  ,@uuid,  @custID,@country,@company_name,
	@business_id,@person_to_contact,@person_to_contact_email,@person_to_quick_pay_email,@delivery_address,@zip_code,@city,
	@web_invoice,@delivery_method,@finvoice_operator,@customer_type)
	
    END

	


		--exec [sp_AddInvoiceCustInfo]  @invoiceid,@uuid,@customerID,@country,@company_name,
		--@business_id,@person_to_contact,@person_to_contact_email,@person_to_quick_pay_email,@delivery_address,@zip_code,@city,
		--@web_invoice,@delivery_method,@customer_type
	
		--select @invoiceid as invoice_id,@custID as @customersid  

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
