SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_AddInvoiceExpenses_partialPay]
(  
     @place_of_purchase varchar(255),  
     @date_of_purchase date,
	 @attach_option varchar(100),
	 @InvoiceExpensesItems as dbo.TabledInvoiceExpense_Itemsinfo READONLY, 
	 @uuid uniqueidentifier,	
	 @expenseId bigint output,
	 --partialPay
	 @invoice_id bigint = null,	 
	 @base_invoice_id bigint = null,
	 @base_invoice_expense_id bigint = null,
	 @base_expense_document_id bigint = null,
	 @path varchar(512) = null,
	 @filename varchar(512) = null,
	 @fileId uniqueidentifier,
	 @filetype varchar(128) = null
	 --@partial_expense_received [decimal] (10,2) = 0
	 --partialPay
 )  
AS   
BEGIN
BEGIN TRY
BEGIN TRANSACTION

declare @invoice_expense_id bigint

		IF(@base_invoice_expense_id IS NULL)
		BEGIN
		insert into document(uuid,fileId,path,filename,filetype,place_of_purchase,date_of_purchase)
		 values(@uuid,@fileId,@path,@filename,@filetype,@place_of_purchase,@date_of_purchase)   

		 declare  @document_ID bigint
		 SET @document_ID = @@IDENTITY;
		 --print 'docuem' + @document_ID
		 END
		 ELSE
		 BEGIN
			SET @document_ID = @base_expense_document_id
		 END

		INSERT INTO invoice_expense
		(	
			[uuid],			  
			[document_id],  
			[place_of_purchase],  
			[date_of_purchase],
			[attach_option]

		)VALUES
		(  
			@uuid,			
			@document_id,
			@place_of_purchase,
			@date_of_purchase,
			@attach_option
		)
		
		SET @invoice_expense_id = @@IDENTITY;
		 --print 'expense' + @invoice_expense_id

--PartialPay
IF(@base_invoice_expense_id IS NOT NULL)
  BEGIN
  
	UPDATE invoice_expense set is_partial = 1 where 
	invoice_expense_id = @invoice_expense_id

  --UPDATE invoice_expense set invoice_id = @invoice_id, added_to_invoice = 1, 
  --attach_option = 'add_to_invoice' where invoice_expense_id=@invoice_expense_id

  --Update invoice_expense set partial_expense_received=@partial_expense_received
  --where invoice_expense_id = @base_invoice_expense_id and uuid = @uuid

  DECLARE @original_invoice_expense_id bigint

  IF EXISTS (SELECT * FROM invoice_expense_partial_info WHERE invoice_expense_id = @base_invoice_expense_id and uuid = @uuid)
	SET @original_invoice_expense_id = (SELECT TOP 1 original_invoice_expense_id FROM invoice_expense_partial_info 
	WHERE invoice_expense_id = @base_invoice_expense_id and uuid = @uuid ORDER BY original_invoice_expense_id)	
  ELSE
    SET @original_invoice_expense_id=@base_invoice_expense_id 

  Insert into invoice_expense_partial_info(invoice_expense_id, uuid, base_invoice_expense_id, original_invoice_expense_id, base_invoice_id)
  (Select @invoice_expense_id, uuid, @base_invoice_expense_id, @original_invoice_expense_id, @base_invoice_id  from invoice_expense where            
  invoice_expense_id = @base_invoice_expense_id and uuid = @uuid)
  END
--PartialPay

Exec dbo.[sp_AddInvoiceExpense_Items]  @InvoiceExpensesItems,@invoice_expense_id

 --Added to return expense_id
 select @invoice_expense_id as expenseId

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
