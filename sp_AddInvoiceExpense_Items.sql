SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_AddInvoiceExpense_Items]
(
@invoice_expense_items AS dbo.TabledInvoiceExpense_Itemsinfo READONLY,
@invoice_expense_id bigint, 
--partialPay change
@partial_invoice_expense_id bigint = 1
)

AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION

      INSERT INTO invoice_expense_items(invoice_expense_item_id,
	  invoice_expense_id, partial_invoice_expense_id, description, sum, vat)
      SELECT invoice_expense_item_id, @invoice_expense_id, @partial_invoice_expense_id, description, sum, vat FROM @invoice_expense_items
	   

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
