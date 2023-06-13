SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_AddCompanyUpdate]
( 
 @newsupdate varchar(5000)  
 )  
AS   
BEGIN   
BEGIN TRY
BEGIN TRANSACTION  
 insert into CompanyUpdates(newsupdate) values(
 @newsupdate)
	
Declare @lastrecord int=IDENT_CURRENT('CompanyUpdates')
update CompanyUpdates set deleted_at=dbo.dReturnDate(deleted_at),created=dbo.dReturnDate(created),
last_modified_date =dbo.dReturnDate(last_modified_date) where id=@lastrecord



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
