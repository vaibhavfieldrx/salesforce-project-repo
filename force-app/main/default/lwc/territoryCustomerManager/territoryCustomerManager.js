import { LightningElement, wire, track } from 'lwc';
import getTerritoryCustomers
    from '@salesforce/apex/TerritoryCustomerController.getTerritoryCustomers';

export default class TerritoryCustomerManager extends LightningElement {

    @track customers = [];
    @track filteredCustomers = [];
    @track selectedCustomer;

    searchKey = '';

    @wire(getTerritoryCustomers)
    wiredData({ data, error }) {
        if (data) {
            // 🔹 Flatten customers + prepare UI fields
            this.customers = data.flatMap(t =>
                t.customers.map(c => {

                     console.log("cust : ");
                    console.log(c);
                    const isActive = c.Active__c === 'Yes';

                    return {
                        accountId: c.accountId,
                        name: c.name,
                        email: c.email,
                        phone: c.phone,
                        address: c.address,
                        territory: t.territoryName,

                        // 👇 UI-ready fields (IMPORTANT)
                        status: isActive ? 'Active' : 'Inactive',
                        statusClass: isActive
                            ? 'status active'
                            : 'status inactive'
                    };
                })
            );

            this.filteredCustomers = [...this.customers];
        }

        if (error) {
            console.error('Error fetching territory customers', error);
        }
    }

    // 🔍 Search ONLY customers (name + email)
    handleSearch(event) {
        const key = event.target.value.toLowerCase();

        this.filteredCustomers = this.customers.filter(c =>
            c.name.toLowerCase().includes(key) ||
            (c.email && c.email.toLowerCase().includes(key))
        );
    }

    // 👉 Click customer → show details on right
    selectCustomer(event) {
        const accountId = event.currentTarget.dataset.id;
        this.selectedCustomer =
            this.customers.find(c => c.accountId === accountId);
    }
}