import { LightningElement, wire, track } from 'lwc';
import getTerritoryCustomers
    from '@salesforce/apex/TerritoryCustomerController.getTerritoryCustomers';

export default class TerritoryCustomerManager extends LightningElement {

    @track customers = [];
    @track filteredCustomers = [];
    @track selectedCustomer;

    searchKey = '';
    pageSize = 10;        // customers per page
    currentPage = 1;
    totalPages = 0;

    allCustomers = [];   

    @wire(getTerritoryCustomers)
    wiredData({ data, error }) {
        if (data) {
            this.allCustomers = data.flatMap(t =>
                t.customers.map(c => {
                    const isActive = c.activeFlag === 'Yes';

                    return {
                        accountId: c.accountId,
                        name: c.name,
                        email: c.email,
                        phone: c.phone,
                        address: c.address,
                        territory: t.territoryName,
                        status: isActive ? 'Active' : 'Inactive',
                        statusClass: isActive
                            ? 'status active'
                            : 'status inactive'
                    };
                })
            );

            this.currentPage = 1;
            this.updatePagination();
        }

        if (error) {
            console.error(error);
        }
    }

    // 🔍 Search ONLY customers (name + email)
    // handleSearch(event) {
    //     const key = event.target.value.toLowerCase();

    //     this.filteredCustomers = this.customers.filter(c =>
    //         c.name.toLowerCase().includes(key) ||
    //         (c.email && c.email.toLowerCase().includes(key))
    //     );
    // }

    handleSearch(event) {
        this.searchKey = event.target.value.toLowerCase();
        this.currentPage = 1;
        this.updatePagination();
    }

    // 👉 Click customer → show details on right
    selectCustomer(event) {
        const accountId = event.currentTarget.dataset.id;
        this.selectedCustomer =
            this.customers.find(c => c.accountId === accountId);
    }

    updatePagination() {
        this.totalPages = Math.ceil(this.filteredSource.length / this.pageSize);

        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;

        this.filteredCustomers = this.filteredSource.slice(start, end);
    }

    get filteredSource() {
        return this.searchKey
            ? this.allCustomers.filter(c =>
                c.name.toLowerCase().includes(this.searchKey) ||
                (c.email && c.email.toLowerCase().includes(this.searchKey))
            )
            : this.allCustomers;
    }

    handlePrev() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updatePagination();
        }
    }

    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updatePagination();
        }
    }

    get disablePrev() {
        return this.currentPage === 1;
    }

    get disableNext() {
        return this.currentPage === this.totalPages;
    }
}