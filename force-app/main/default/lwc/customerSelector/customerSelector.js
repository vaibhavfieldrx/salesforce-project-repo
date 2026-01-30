import { LightningElement, wire, track, api } from 'lwc';
import getCustomers from '@salesforce/apex/CustomerController.getCustomers';

export default class CustomerSelector extends LightningElement {

    @track options = [];
    customers = []; // ✅ store full customer records

       @api selectedCustomerId;   // ✅ RECEIVED FROM PARENT
    @api disabled = false;     // ✅ EDIT MODE SUPPORT

    @wire(getCustomers)
    wiredCustomers({ data, error }) {
        if (data) {
            this.customers = data; // ✅ save raw data
            console.log("dataa" , data)
            this.options = data.map(c => ({
                label: c.accountName,
                value: c.accountId
            }));
        } else if (error) {
            console.error(error);
        }
    }

    handleChange(event) {
        const selectedId = event.detail.value;
this.selectedCustomerId = selectedId;
        const selectedCustomer = this.customers.find(
            c => c.accountId === selectedId
        );

        if (!selectedCustomer) return;

        console.log('selectedCustomer', selectedCustomer);

        this.dispatchEvent(
            new CustomEvent('customerselect', {
                detail: {
                    accountId: selectedCustomer.accountId,
                    name: selectedCustomer.accountName,
                    phone: selectedCustomer.Phone,
                    billingContactId: selectedCustomer.contactId // if available
                }
            })
        );
    }
}
