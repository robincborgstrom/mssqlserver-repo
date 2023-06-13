SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_AddAllowancePassengers]  
(  
@Passengers AS dbo.TabledAllowancePassengers READONLY,  
@id int 
)  
  
AS  
BEGIN  

	BEGIN TRY
		BEGIN TRANSACTION
		   INSERT INTO allowance_passenger(  
		   allowance_id,id,passenger)  
		   SELECT   
		   @id, id,passenger FROM @Passengers  
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
