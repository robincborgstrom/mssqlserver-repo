SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_AddInvoiceAllowances_partialPay]
(   	 
     @uuid uniqueidentifier,  
     @destination varchar(100),
	 @country varchar(100),
	 @attach_option varchar(100),
	 @start_date datetime,
	 @start_time time,
	 @end_date datetime,
	 @end_time time,
	 @mileage_allowance bit,
	 @day_allowance bit,
	 @full_time_allowance numeric(18,2),
	 @part_time_allowance numeric(18,2),
	 @meal_allowance numeric(18,2),
	 @distance numeric(18,2),
	 @vehicle_type_id int,
	 @license_plate varchar(50), 
	 @passenger_count int,
	 @additional_vehicle_cost_id int,	 
	 @forest_trail bit,
	 @heavy_load bit,
	 @working_dog bit,
	 @routes as dbo.TabledAllowanceRoute_Itemsinfo READONLY, 
     @passengers as dbo.TabledAllowancePassengers READONLY,
	 @allowanceId bigint output,
	 --partialPay
	 @invoice_id bigint = null,
	 @base_invoice_allowance_id bigint = null,
	 @base_invoice_id bigint = null,
	 @sum_total_allowance numeric(18,2) = 0,
	 @sum_mileage_allowance numeric(18,2) = 0,
	 @sum_full_time_allowance numeric(18,2) = 0,
	 @sum_part_time_allowance numeric(18,2) = 0,	
	 @sum_meal_time_allowance numeric(18,2) = 0	 
	 --partialPay
 )  
AS   
BEGIN
BEGIN TRY
BEGIN TRANSACTION

	declare @id bigint

	INSERT INTO invoice_allowance
	(		  
		[uuid],  
		[destination],
		[country],
		[attach_option],
		[start_date],
		[start_time],
		[end_date],
		[end_time],
		[mileage_allowance],
		[day_allowance],
		[full_time_allowance],
		[part_time_allowance],
		[meal_allowance],
		[distance],
		[vehicle_type_id],
		[license_plate], 
		[passenger_count],
		[additional_vehicle_cost_id],		
		[forest_trail],
		[heavy_load],
		[working_dog]
	)VALUES
	(  		 
		@uuid,  
		@destination,
		@country,
		@attach_option,
		@start_date,
		@start_time,
		@end_date,
		@end_time,
		@mileage_allowance,
		@day_allowance,
		@full_time_allowance,
		@part_time_allowance,
		@meal_allowance,
		@distance,
		@vehicle_type_id,
		@license_plate, 
		@passenger_count,
		@additional_vehicle_cost_id,		
		@forest_trail,
		@heavy_load,
		@working_dog
	)
	
	SET @id = @@IDENTITY;

--PartialPay
IF(@base_invoice_allowance_id IS NOT NULL)
  BEGIN
  UPDATE invoice_allowance set 
  invoice_id = @invoice_id, 
  added_to_invoice = 1, 
  attach_option = 'add_to_invoice',
  is_partial = 1,
  sum_mileage_allowance = @sum_mileage_allowance,
  sum_full_time_allowance = @sum_full_time_allowance,
  sum_part_time_allowance = @sum_part_time_allowance,
  sum_meal_time_allowance = @sum_meal_time_allowance,
  sum_total_allowance = @sum_total_allowance
  where id=@id 	

  DECLARE @original_invoice_allowance_id bigint

  IF EXISTS (SELECT * FROM Invoice_allowance_partial_info WHERE id = @base_invoice_allowance_id and uuid = @uuid)
	SET @original_invoice_allowance_id = (SELECT TOP 1 original_invoice_allowance_id FROM Invoice_allowance_partial_info 
	WHERE id = @base_invoice_allowance_id and uuid = @uuid ORDER BY original_invoice_allowance_id)	
  ELSE
    SET @original_invoice_allowance_id=@base_invoice_allowance_id 

  Insert into Invoice_allowance_partial_info(id, uuid, base_invoice_allowance_id, original_invoice_allowance_id, base_invoice_id)
  (Select @id, uuid, @base_invoice_allowance_id, @original_invoice_allowance_id, @base_invoice_id from invoice_allowance where            
  id = @base_invoice_allowance_id and uuid = @uuid)
  END
  ELSE
  BEGIN
	 update     
 invoice_allowance set    
 sum_mileage_allowance=isnull(distance    
 *((select value from Allowance_cost where id=@vehicle_type_id and year= year(@start_date)    )+    
 ((select value from allowance_cost where id = 9 and  year= year(@start_date) )*@working_dog)+    
 ((select value from allowance_cost where id=8 and year= year(@start_date) )*@heavy_load)+    
 ((select value from allowance_cost where id=7 and year= year(@start_date) )*@forest_trail)+    
 ((select value from Allowance_cost  where id=6 and year= year(@start_date) )*@passenger_count)+    
 (select value from Allowance_cost where id=@additional_vehicle_cost_id and year= year(@start_date) )),0),     
  sum_full_time_allowance =ISNULL(full_time_allowance     
  -- price for the country/region    
 * ISNULL( (select price from CountryFullTimeAllowance where country_id=@country and year= year(@start_date)    ),    
    (ISNULL((select price from RegionFullTimeAllowance where region_id= @country and year= year(@start_date)    ),0))),0),    
    
  sum_part_time_allowance = isnull(part_time_allowance    
 * (select value from Allowance_cost where id=4 and year= year(@start_date) ),0),    
    
  sum_meal_time_allowance = isnull(meal_allowance    
 * (select value from Allowance_cost where id=5 and year= year(@start_date)  ),0)    
 where id=@id     
    
 update invoice_allowance set sum_total_allowance=isnull((sum_full_time_allowance+sum_part_time_allowance+    
      sum_meal_time_allowance+sum_mileage_allowance),0)    
 where id=@id	
  END
  --PartialPay

	Exec dbo.[sp_AddInvoiceAllowanceRoute_Items]  @routes,@id

	Exec dbo.[sp_AddAllowancePassengers]  @passengers,@id

 --Added to return allowance_id
 select @id as allowanceId
  
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
