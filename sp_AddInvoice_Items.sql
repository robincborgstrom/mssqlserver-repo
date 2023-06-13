SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_AddInvoice_Items]
(@invoice_items AS dbo.TabledInvoice_Itemsinfo_refactored READONLY,
--@invoice_items AS dbo.TabledInvoice_itemsinfo READONLY,
@invoice_id bigint,
@uuid uniqueidentifier,
--partialPay change
@partial_invoice_id bigint = 1)
AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION
      
	  INSERT INTO Invoice_items (invoice_item_id,invoice_id,partial_invoice_id,uuid,description,start_date,end_date,quantity,unit,quantity_price,vat_percent,vat,sum_tax_free,invoice_expense_id,invoice_allowance_id,partial_invoice_expense_id,partial_invoice_allowance_id)
      SELECT invoice_item_id, @invoice_id, @partial_invoice_id, @uuid, description, start_date,end_date,quantity,unit,quantity_price,vat_percent,vat,sum_tax_free,invoice_expense_id,invoice_allowance_id,partial_invoice_expense_id,partial_invoice_allowance_id FROM @invoice_items

	  update invoice_expense set added_to_invoice =1, attach_option = 'add_to_invoice', invoice_id=@invoice_id, partial_invoice_id=@partial_invoice_id
	  where invoice_expense_id in (select invoice_expense_id from @invoice_items)

	  --Fix for detaching the removed expenses from an invoice item list
	  update invoice_expense set added_to_invoice = 0, invoice_id=NULL, partial_invoice_id=NULL where invoice_id=@invoice_id and partial_invoice_id=@partial_invoice_id and added_to_invoice = 1 and
	  invoice_expense_id not in (select invoice_expense_id from @invoice_items)
	  --Fix ended

	  update invoice_allowance set added_to_invoice =1, attach_option = 'add_to_invoice', invoice_id=@invoice_id, partial_invoice_id=@partial_invoice_id
	  where id in (select invoice_allowance_id from @invoice_items)

	  --Fix for detaching the removed allowances from an invoice item list
	  update invoice_allowance set added_to_invoice = 0, invoice_id = NULL, partial_invoice_id=NULL where invoice_id = @invoice_id and partial_invoice_id=@partial_invoice_id and added_to_invoice = 1 and
	  id not in (select invoice_allowance_id from @invoice_items)
	  --Fix ended
	 
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
