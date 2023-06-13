SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*  
First add run this in kvt_db  
  ALTER TABLE [dbo].[Invoice] ADD credit_note_from_invoice BIGINT;  
*/  
CREATE PROCEDURE [dbo].[sp_AddCreditNote] (  
@invoice_id BIGINT,  
@uuid UNIQUEIDENTIFIER)  
AS  
  BEGIN  
      BEGIN try  
         BEGIN TRANSACTION  
           
   DECLARE @newinvoice_id BIGINT
   DECLARE @newpartial_invoice_id bigINT
   --IF NOT EXISTS (select * from dbo.Invoice where @invoice_id = credit_note_from_invoice)/*this is the case where a credit invoice already exists for some invoice*/  
   --BEGIN  
  
   IF EXISTS (select * from dbo.Invoice where @invoice_id = invoice_id AND credit_note_from_invoice IS NULL)/*if no credit invoice exist from current invoice create one*/  
   BEGIN  
     
    IF NOT EXISTS (SELECT * FROM   dbo.invoice WHERE  uuid = @uuid)
	BEGIN 
		SET @newinvoice_id = 1
		SET @newpartial_invoice_id = 1
	END
     ELSE
	 BEGIN
    SET @newinvoice_id = (SELECT Max(i.invoice_id) + 1 FROM   invoice i)
	SET @newpartial_invoice_id = 1
	END
  
     INSERT INTO dbo.invoice  
        (  
         uuid,  
         invoice_id,
		 partial_invoice_id,
         customer_id,  
         [description],  
         job_title,  
         invoice_reference,  
         billing_date,  
         due_date,  
         overdue,  
         total_sum,  
         instant_payment,  
         status,  
         building_service,  
         invoice_price_selection,  
         interestfee,  
        -- person_to_quick_pay_email,  
         invoice_lang  
         )  
     SELECT   
      uuid,  
      @newinvoice_id,
	  @newpartial_invoice_id,
      customer_id,  
      [description],  
      job_title,  
      invoice_reference,  
      billing_date,  
      due_date,  
      overdue,  
      -total_sum,  
      instant_payment,  
      [status],  
      building_service,  
      invoice_price_selection,  
      interestfee,  
      --person_to_quick_pay_email,  
      invoice_lang  
     FROM   dbo.invoice  
     WHERE  invoice_id = @invoice_id  
      AND uuid = @uuid  
  
     INSERT INTO invoice_customer_info  
        (  
        invoice_id,
		partial_invoice_id,
         uuid,  
         customer_id,  
         country,  
         company_name,  
         business_id,  
         person_to_contact,  
         person_to_contact_email,  
         person_to_quick_pay_email,  
         delivery_address,  
         zip_code,  
         city,  
         web_invoice,  
         delivery_method,  
         finvoice_operator,  
         customer_type  
         )  
     SELECT   
         @newinvoice_id,
		 @newpartial_invoice_id,
         @uuid,  
         customer_id,  
         country,  
         company_name,  
         business_id,  
         person_to_contact,  
         person_to_contact_email,  
        person_to_quick_pay_email,  
         delivery_address,  
         zip_code,  
         city,  
         web_invoice,  
         delivery_method,  
         finvoice_operator,  
         customer_type  
     FROM   customers  
     WHERE  uuid = @uuid  
      AND customer_id IN (SELECT TOP 1 customer_id  
           FROM   invoice  
           WHERE  invoice_id = @newinvoice_id  
            AND uuid = @uuid)  
  
          
     UPDATE dbo.Invoice  
     SET    status = 0,  
      credit_note_from_invoice = @invoice_id  
     WHERE  invoice_id = @newinvoice_id  
      AND uuid = @uuid  
  
     INSERT INTO dbo.invoice_items  
        (invoice_item_id,  
         invoice_id,
		 partial_invoice_id,
         [description],  
         quantity,  
         unit,  
         quantity_price,  
         start_date,  
         end_date,  
         vat,  
         vat_percent,  
         sum_tax_free,  
         uuid,  
         invoice_expense_id,  
      invoice_allowance_id)  
     SELECT invoice_item_id,  
      @newinvoice_id,
	  @newpartial_invoice_id,
      [description],  
      quantity,  
      unit,  
      -quantity_price,  
      start_date,  
      end_date,  
      -vat,  
      vat_percent,  
      -sum_tax_free,  
      uuid,  
      invoice_expense_id,  
      invoice_allowance_id  
     FROM   invoice_items  
     WHERE  invoice_id = @invoice_id  
      AND uuid = @uuid  
  
     EXEC dbo.Sp_getinvoicesbyinvoiceid @invoice_id = @newinvoice_id, @uuid = @uuid  
          END  
  
    
  Commit  
 END try  
  
      BEGIN catch  
          IF @@TRANCOUNT > 0  
            BEGIN  
                ROLLBACK  
  
          EXEC dbo.Sp_kvterrorlogging  
            END;  
  
          THROW;  
      END catch  
  END
GO
