import { LightningElement, wire, track } from 'lwc';
import getTerritories from '@salesforce/apex/AccountTerritoryController.getTerritories';
import getAccountsByTerritory from '@salesforce/apex/AccountTerritoryController.getAccountsByTerritory';

export default class AccountByTerritory extends LightningElement {

    @track territoryOptions = [];
    @track accounts = [];
    @track filteredAccounts = [];

    selectedTerritory;

    pageSize = 10;
    currentPage = 1;
    totalRecords = 0;

    @wire(getTerritories)
    wiredTerritories({ data, error }) {
        if (data) {
            this.territoryOptions = data.map(t => ({
                label: t.Name,
                value: t.Id
            }));
        } else if (error) {
            console.error('Error loading territories', error);
        }
    }

    handleTerritoryChange(event) {
        this.selectedTerritory = event.detail.value;
        this.currentPage = 1;
        this.loadAccounts();
    }

    loadAccounts() {
        getAccountsByTerritory({ territoryId: this.selectedTerritory })
            .then(result => {

                this.accounts = result.map((acc, index) => ({
                    ...acc,
                    rowNumber: index + 1,
                    emailLink: acc.Email__c ? `mailto:${acc.Email__c}` : '',
                     displayRevenue: acc.AnnualRevenue ? acc.AnnualRevenue : 0
                }));

                this.filteredAccounts = this.accounts;
                this.totalRecords = this.accounts.length;
                this.currentPage = 1;
            })
            .catch(error => {
                console.error('Error loading accounts', error);
            });
    }

    get showHeader() {
        return this.selectedTerritory;
    }

    get paginatedAccounts() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;
        return this.filteredAccounts.slice(start, end);
    }

    get totalPages() {
        return Math.ceil(this.totalRecords / this.pageSize);
    }

    get disablePrevious() {
        return this.currentPage === 1;
    }

    get disableNext() {
        return this.currentPage === this.totalPages;
    }

    handlePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
        }
    }

    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
        }
    }
}






























































































// import { LightningElement, wire, track } from 'lwc';
// import getTerritories from '@salesforce/apex/AccountTerritoryController.getTerritories';
// import getAccountsByTerritory from '@salesforce/apex/AccountTerritoryController.getAccountsByTerritory';

// export default class AccountByTerritory extends LightningElement {

//     @track territoryOptions = [];       
//     @track accounts = [];               
//     @track filteredAccounts = [];       

//     selectedTerritory;                  

//     pageSize = 10;
//     currentPage = 1;
//     totalRecords = 0;

//     columns = [
//         { label: 'Customer Name', fieldName: 'Name' },
//         { label: 'Phone', fieldName: 'Phone' },
//         { label: 'Email', fieldName: 'Email__c' },
//         { label: 'Account Source', fieldName: 'AccountSource' },
//         { label: 'Account Type', fieldName: 'Type' },
//         { label: 'Annual Revenue', fieldName: 'AnnualRevenue', type: 'currency' },
//         { label: 'Field Executive', fieldName: 'Field_Executive__c' },
//         { label: 'Industry', fieldName: 'Industry' },
//         { label: 'Rating', fieldName: 'Rating' },
//         { label: 'Account Owner', fieldName: 'Owner.Name' }
//     ];

//     @wire(getTerritories)
//     wiredTerritories({ data, error }) {
//         if (data) {
//             this.territoryOptions = data.map(t => ({
//                 label: t.Name,
//                 value: t.Id
//             }));
//         } else if (error) {
//             console.error('Error loading territories', error);
//         }
//     }

//     handleTerritoryChange(event) {
//         this.selectedTerritory = event.detail.value;
//         this.currentPage = 1;
//         this.loadAccounts();
//     }

//     loadAccounts() {
//         getAccountsByTerritory({ territoryId: this.selectedTerritory })
//             .then(result => {
//                 this.accounts = result;
//                 this.filteredAccounts = result;
//                 this.totalRecords = result.length;
//                 this.currentPage = 1;
//             })
//             .catch(error => {
//                 console.error('Error loading accounts', error);
//             });
//     }

//     get showHeader() {
//         return this.selectedTerritory && this.filteredAccounts.length >= 0;
//     }

//     get paginatedAccounts() {
//         const start = (this.currentPage - 1) * this.pageSize;
//         const end = start + this.pageSize;
//         return this.filteredAccounts.slice(start, end);
//     }

//     get totalPages() {
//         return Math.ceil(this.totalRecords / this.pageSize);
//     }

//     get disablePrevious() {
//         return this.currentPage === 1;
//     }

//     get disableNext() {
//         return this.currentPage === this.totalPages;
//     }

//     handlePrevious() {
//         if (this.currentPage > 1) {
//             this.currentPage--;
//         }
//     }

//     handleNext() {
//         if (this.currentPage < this.totalPages) {
//             this.currentPage++;
//         }
//     }

//     get indexOffset() {
//         return (this.currentPage - 1) * this.pageSize + 1;
//     }

// }