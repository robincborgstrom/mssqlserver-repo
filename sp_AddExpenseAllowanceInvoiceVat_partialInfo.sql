SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_AddExpenseAllowanceInvoiceVat_partialInfo]
(
@invoice_expense_items AS dbo.TabledInvoiceExpenseItems_partialInfo1 READONLY,
@invoice_allowance_vat AS dbo.TabledInvoice_partial_allowance_vat_info3 READONLY,
@invoice_items AS dbo.TabledInvoiceItems_partialInfo1 READONLY
)

AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION

      INSERT INTO invoice_expense_items_partial_info(invoice_expense_item_id,
	  invoice_expense_id,partial_invoice_expense_id,partial_expense_received_with_vat,vat_percent)
      SELECT Invoice_expense_Item_id, invoice_expense_id, partial_invoice_expense_id, 
	  partial_expense_received_with_vat, vat_percent FROM @invoice_expense_items

	  INSERT INTO invoice_partial_allowance_vat_info(id,
	  partial_invoice_allowance_id,
	  invoice_id,
	  partial_invoice_id,
	  uuid,
	  partial_allowance_received_without_vat,
	  vat_percent,
	  sum_full_time_allowance,
	  sum_part_time_allowance,
	  sum_meal_time_allowance,
	  sum_mileage_allowance,
	  sum_total_allowance,
	  distance,
	  full_time_allowance,
	  part_time_allowance,
	  meal_allowance,
	  vat_received
	  )
      SELECT id, 
	  partial_invoice_allowance_id,	  
	  invoice_id,
	  partial_invoice_id,
	  uuid,
	  partial_allowance_received_without_vat,
	  vat_percent,
	  sum_full_time_allowance,
	  sum_part_time_allowance,
	  sum_meal_time_allowance,
	  sum_mileage_allowance,
	  sum_total_allowance,
	  distance,
	  full_time_allowance,
	  part_time_allowance,
	  meal_allowance,
	  vat_received
	  FROM @invoice_allowance_vat

	  INSERT INTO invoice_items_partial_info(Invoice_item_id,
	  invoice_id, partial_invoice_id, uuid, partial_invoice_received_with_vat, vat_percent)
      SELECT Invoice_item_id, invoice_id, partial_invoice_id, uuid, 
	  partial_invoice_received_with_vat, vat_percent FROM @invoice_items
	   
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
