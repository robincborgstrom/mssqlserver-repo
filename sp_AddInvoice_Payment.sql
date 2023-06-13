SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_AddInvoice_Payment]
(  
 @invoice_id bigint,  
 @total_sum DECIMAL,
 @reference varchar(255),
 @payment_date DATE,  
 @delivery_method Varchar(255)
)  
AS   
BEGIN
BEGIN TRY
BEGIN TRANSACTION   
  
	INSERT INTO Invoice_payment
	(  
		[invoice_id],  
		[total_sum],  
		[reference],  
		[payment_date],  
		[delivery_method]  
	)VALUES
	(  
		@invoice_id,
		@total_sum,  
		@reference,
		@payment_date,
		@delivery_method);
  
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
