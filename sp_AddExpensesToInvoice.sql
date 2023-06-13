SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_AddExpensesToInvoice](
    @expenseids varchar(200)
)
AS 
BEGIN 
BEGIN TRY
BEGIN TRANSACTION
	
	SELECT * into #expenseids FROM STRING_SPLIT(@expenseids,',')
	select   b.invoice_expense_id,
		    'Kulut- '+description as description,
			 1 as quantity,
			'kpl' as unit,
			--Cast(Round(Convert(float,sum/(1+(vat*0.01))),2,1) as decimal(18,2)) as quantity_price,

			 Cast(Round(sum/(1+(vat*0.01)),2) as decimal(18,2)) as quantity_price,
			 Cast(Round(sum/(1+(vat*0.01)),2) as decimal(18,2)) as sum_tax_free,
			 CAST(vat AS int) as vat_percent,
			 Cast(sum-Round(sum/(1+(vat*0.01)),2) as decimal(18,2)) as vat,
			 --CAST(vat*0.01* Round(sum/(1+(vat*0.01)),2,1) as decimal(10,2)) AS vat,
			 sum as sum_with_vat, 
			 b.date_of_purchase as start_date,
			 b.date_of_purchase as end_date,
			 '-1' as invoice_allowance_id
	 from invoice_expense_items a 
	 inner join invoice_expense b on  a.invoice_expense_id=b.invoice_expense_id
	 where b.invoice_expense_id in (select * from #expenseids) and b.deleted=0 and a.deleted=0

	 drop table #expenseids
	

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
