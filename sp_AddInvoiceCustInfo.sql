SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_AddInvoiceCustInfo]    
( @newinvoiceid bigint,
  @uuid uniqueidentifier,
    @customersid bigint,
	@country varchar(500),
	@company_name varchar(500),
	@business_id varchar(500),
	@person_to_contact varchar(500),
	@person_to_contact_email varchar(500),
	@person_to_quick_pay_email varchar(500),
	@delivery_address varchar(500),
	@zip_code varchar(500),
	@city varchar(500),
	@web_invoice varchar(500),
	@delivery_method varchar(500),
	@customer_type varchar(500)  
 )
 As 
 Begin
 INSERT INTO TestCust  values ( @newinvoiceid, @customersid)
 
INSERT INTO invoice_customer_info (invoice_id,uuid,customer_id,country,
	company_name,business_id,person_to_contact,person_to_contact_email,person_to_quick_pay_email,
	delivery_address,zip_code,city,web_invoice,delivery_method,customer_type)
	values( @newinvoiceid  ,@uuid,  @customersid,@country,@company_name,
	@business_id,@person_to_contact,@person_to_contact_email,@person_to_quick_pay_email,@delivery_address,@zip_code,@city,
	@web_invoice,@delivery_method,@customer_type)

End		
GO
