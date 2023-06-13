SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_AddAllowanceToInvoice](
    @allowanceids varchar(200)
)
AS 
BEGIN 
BEGIN TRY
BEGIN TRANSACTION
	
	SELECT * into #temp FROM STRING_SPLIT(@allowanceids,',')
	
	select   '-1' as invoice_expense_id,
		    'Matkakorvaus- '+destination as description,
			 1 as quantity,
			'kpl' as unit,
			 sum_total_allowance as quantity_price,
			 24 as vat_percent,
			 start_date as start_date,
			 end_date as end_date,
			 id as invoice_allowance_id
	 from invoice_allowance
	 where id in (select * from #temp) and deleted=0
	 drop table #temp
	
	

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
