SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_AddInvoice_row]
(  
 @invoice_id bigint,  
 @description varchar(512),
 @start_date date,
 @end_date date,  
 @qunatity varchar(255),
 @unit varchar(40),
 @quantity_price decimal,
 @vat_percent decimal,
 @vat_rule int,
 @sum_tax_free decimal
)  
AS   
BEGIN   
BEGIN TRY
BEGIN TRANSACTION
	INSERT INTO Invoice_row
	(
		[invoice_id],  
		[description],  
		[start_date],  
		[end_date],  
		[quantity], 
		[unit],  
		[quantity_price],  
		[vat_percent],  
		[vat_rule], 
		[sum_tax_free] 
	  
	)VALUES
	(  
		@invoice_id,  
		@description,
		@start_date,
		@end_date,  
		@qunatity,
		@unit,
		@quantity_price,
		@vat_percent,
		@vat_rule,
		@sum_tax_free);
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
