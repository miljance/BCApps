namespace Microsoft.SubscriptionBilling;

using Microsoft.Sales.Document;

reportextension 8001 BatchPostSalesInvoices extends "Batch Post Sales Invoices"
{
    dataset
    {
        modify("Sales Header")
        {
            trigger OnBeforePostDataItem()
            begin
                //TODO: Clarify if we should filter documents from Contract Billing only when the option is enabled.
            end;
        }

    }
    requestpage
    {
        layout
        {
            addlast(Options)
            {
                field(AutoContractBilling; AutoContractBilling)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Auto Contract Billing';
                    ToolTip = 'Specifies if you want to post invoices automatically created from subscription billing.';
                }
            }
        }
    }
    var
        AutoContractBilling: Boolean;
}
