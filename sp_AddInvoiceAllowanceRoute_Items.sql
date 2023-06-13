SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_AddInvoiceAllowanceRoute_Items]
(
@InvoiceAllowanceRouteItems AS dbo.TabledAllowanceRoute_Itemsinfo READONLY,
@id int )

AS
BEGIN
BEGIN TRY
BEGIN TRANSACTION
      INSERT INTO invoice_allowanceroute_items(
	  allowance_id,id,route)
      SELECT 
	  @id,id,route FROM @InvoiceAllowanceRouteItems

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
