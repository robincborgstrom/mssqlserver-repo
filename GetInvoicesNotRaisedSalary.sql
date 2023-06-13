SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[GetInvoicesNotRaisedSalary] 
AS     
BEGIN  
BEGIN TRY
BEGIN TRANSACTION
	
	select distinct isnull(invoice.total_sum,0) as total_sum, invoice.referencenumber, invoice.invoice_id ,invoice.uuid,u.email from Invoice
	inner join  SalariesInvoice on SalariesInvoice.uuid <>invoice.uuid 
	and SalariesInvoice.invoice_id <>invoice.invoice_id
	inner join user_info  u on u.uuid=invoice.uuid
	where  status in(2,5) and invoicepaid=1 and invoice.deleted=0 and u.deleted=0

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
