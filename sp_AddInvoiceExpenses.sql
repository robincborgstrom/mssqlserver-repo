SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_AddInvoiceExpenses]
(  
     @place_of_purchase varchar(255),  
     @date_of_purchase date,
	 @attach_option varchar(100),
	 @InvoiceExpensesItems as dbo.TabledInvoiceExpense_Itemsinfo READONLY, 
	 @uuid uniqueidentifier,	
	 @expenseId bigint output,
	 --partialPay change
	 @partialExpenseId bigint output,
	 @base_invoice_expense_id bigint = 0,
	 @base_expense_document_id bigint = 0,
	 @path varchar(512) = null,
	 @filename varchar(512) = null,
	 @fileId uniqueidentifier,
	 @filetype varchar(128) = null	 
	 --partialPay change
 ) 
AS   
BEGIN
BEGIN TRY
BEGIN TRANSACTION

declare @invoice_expense_id bigint
declare @partial_invoice_expense_id bigint

IF NOT EXISTS (SELECT * FROM invoice_expense)  
BEGIN   
	SET @invoice_expense_id=1
	SET @partial_invoice_expense_id = 1
END   
ELSE
BEGIN	
		IF(@base_invoice_expense_id IS NULL OR @base_invoice_expense_id = 0)
		BEGIN
		insert into document(uuid,fileId,path,filename,filetype,place_of_purchase,date_of_purchase)
		 values(@uuid,@fileId,@path,@filename,@filetype,@place_of_purchase,@date_of_purchase) 

		 Declare @document_ID bigint
		 SET @document_ID = @@IDENTITY;	
		 
		 SET @invoice_expense_id=(SELECT MAX(i.invoice_expense_id)+1 FROM invoice_expense i)
		 SET @partial_invoice_expense_id = 1
		 END
		 ELSE
		 BEGIN
			SET @document_ID = @base_expense_document_id

			SET @invoice_expense_id = @base_invoice_expense_id		
			SET @partial_invoice_expense_id=(SELECT MAX(i.partial_invoice_expense_id)+1 FROM invoice_expense i WHERE i.invoice_expense_id=@base_invoice_expense_id)
		 END
END

		INSERT INTO invoice_expense
		(	[invoice_expense_id],
            [partial_invoice_expense_id],
			[uuid],			  
			[document_id],  
			[place_of_purchase],  
			[date_of_purchase],
			[attach_option]

		)VALUES
		(   @invoice_expense_id,
		    @partial_invoice_expense_id,
			@uuid,			
			@document_id,
			@place_of_purchase,
			@date_of_purchase,
			@attach_option
		)

		--IF(@base_invoice_expense_id IS NOT NULL)		
		--BEGIN			
		--	UPDATE invoice_expense set is_partial = 1 where invoice_expense_id = @invoice_expense_id
		--END

		Exec dbo.[sp_AddInvoiceExpense_Items]  @InvoiceExpensesItems, @invoice_expense_id, @partial_invoice_expense_id

 --Added to return expense_id
 select @invoice_expense_id as expenseId, @partial_invoice_expense_id as partialExpenseId

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


-----------------------------------------------------------------------------------------------------------------

/****** Object:  StoredProcedure [dbo].[sp_AddInvoicePartialInfo]    Script Date: 02/06/2023 12.46.54 ******/
SET ANSI_NULLS ON
GO
