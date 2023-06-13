SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_AddCustomer]
( 
 @country varchar(255),  
 @company_name Varchar(255),  
 @business_id Varchar(255),  
 @person_to_contact Varchar(255),  
 @person_to_contact_email Varchar(255),  
 @delivery_address Varchar(255),  
 @zip_code Varchar(255),  
 @city varchar(255),  
 @web_invoice varchar(255),  
 @delivery_method varchar(255),  
 @uuid uniqueidentifier,  
 @finvoice_operator varchar(255),
 @invoice_price_selection bit,
 @person_to_quick_pay_email varchar(200),
 @customer_type varchar(255)
)  
AS   
BEGIN   
BEGIN TRY
BEGIN TRANSACTION  

	DECLARE @customerID bigint   
	Exec [sp_CustomerExist]  @person_to_contact_email =@person_to_contact_email ,
						 @uuid=@uuid,@company_name=@company_name, @customer_id=@customerID output
    

	IF(@CustomerID IS NULL) 
	Begin
		INSERT INTO Customers(  
			[country],  
			[company_name],  
			[business_id],  
			[person_to_contact],  
			[person_to_contact_email],  
			[delivery_address],  
			[zip_code],  
			[city],  
			[web_invoice],  
			[finvoice_operator],
			[delivery_method],
			[uuid],
			[invoice_price_selection] ,
			[person_to_quick_pay_email],
			[customer_type]
		)VALUES(  
		 @country,   
		 @company_name ,  
		 @business_id ,  
		 @person_to_contact ,  
		 @person_to_contact_email,  
		 @delivery_address ,  
		 @zip_code ,  
		 @city,  
		 @web_invoice,  
		 @finvoice_operator,
		 @delivery_method,
		 @uuid,
		 @invoice_price_selection,
		 @person_to_quick_pay_email,
		 @customer_type
		 );  
	END
	else
	begin
	UPDATE CUSTOMERS SET 
        [country]=@country,
        [company_name]=@company_name,
		[business_id]=@business_id,
		[person_to_contact]=@person_to_contact ,
		[person_to_contact_email]=@person_to_contact_email,
		[delivery_address]=@delivery_address,
		[zip_code]= @zip_code, 
		[city]=@city,
		[web_invoice]=@web_invoice,
		[finvoice_operator]=@finvoice_operator,
		[delivery_method]=@delivery_method,
		[uuid]=@uuid,
		[invoice_price_selection]=@invoice_price_selection,
		[person_to_quick_pay_email]=@person_to_contact_email,
		[customer_type]=@customer_type
	WHERE customer_id=@CustomerID		 	
  end
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
--EXECUTING PROCEDURE  
-- exec dbo.sp_AddCustomer 
--@uuid='8545EE75-71D6-43C6-4A6E-08D5ED501E61',@country='Saksa',
--@delivery_method=' ',@company_name='Finnair',@business_id='12789789',
--@person_to_contact='Pragya',@person_to_contact_email="pragya@kassavirtanen.fi", @delivery_address='',
--@zip_code='',@city='11',@web_invoice=' ',@finvoice_operator ='333'
  
END
GO
