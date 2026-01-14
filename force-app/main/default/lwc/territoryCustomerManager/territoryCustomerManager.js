import { LightningElement, wire, track } from 'lwc';
import getTerritoryCustomers from
    '@salesforce/apex/TerritoryCustomerController.getTerritoryCustomers';

export default class TerritoryCustomerManager extends LightningElement {

    @track allCustomers = [];
    @track filteredCustomers = [];
    @track selectedCustomer;

    searchKey = '';
    pageSize = 8;
    currentPage = 1;
    totalPages = 0;

    @wire(getTerritoryCustomers)
    wiredData({ data }) {
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
                        statusClass: isActive ? 'status active' : 'status inactive'
                    };
                })
            );
            this.updatePagination();
        }
    }

    handleSearch(event) {
        this.searchKey = event.target.value.toLowerCase();
        this.currentPage = 1;
        this.updatePagination();
    }

    get filteredSource() {
        return this.searchKey
            ? this.allCustomers.filter(c =>
                c.name.toLowerCase().includes(this.searchKey) ||
                (c.email && c.email.toLowerCase().includes(this.searchKey))
            )
            : this.allCustomers;
    }

    updatePagination() {
        this.totalPages = Math.ceil(this.filteredSource.length / this.pageSize);
        const start = (this.currentPage - 1) * this.pageSize;
        this.filteredCustomers =
            this.filteredSource.slice(start, start + this.pageSize);
    }

    handlePrev() {
        this.currentPage--;
        this.updatePagination();
    }

    handleNext() {
        this.currentPage++;
        this.updatePagination();
    }

    get disablePrev() {
        return this.currentPage === 1;
    }

    get disableNext() {
        return this.currentPage === this.totalPages;
    }

    get showPagination() {
        return this.filteredCustomers.length > 0 && this.totalPages > 1;
    }

    selectCustomer(event) {
        const id = event.currentTarget.dataset.id;
        this.selectedCustomer =
            this.allCustomers.find(c => c.accountId === id);
    }
}
