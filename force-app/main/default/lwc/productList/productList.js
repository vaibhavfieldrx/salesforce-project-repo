import { LightningElement, wire, track } from 'lwc';
import getAllProducts from '@salesforce/apex/ProductController.getAllProducts';

export default class ProductList extends LightningElement {

    @track products = [];
    @track pagedProducts = [];

    pageSize = 6;
    pageNumber = 1;
    totalPages = 1;

    @wire(getAllProducts)
    wiredProducts({ data, error }) {
        if (data) {
            this.products = data.map(prod => ({
                ...prod,
                activeIcon: prod.isActive ? 'utility:check' : 'utility:close'
            }));

            this.totalPages = Math.ceil(this.products.length / this.pageSize);
            this.updatePage();
        }
        if (error) {
            console.error(error);
        }
    }

    updatePage() {
        const start = (this.pageNumber - 1) * this.pageSize;
        const end = start + this.pageSize;
        this.pagedProducts = this.products.slice(start, end);
    }

    nextPage() {
        if (this.pageNumber < this.totalPages) {
            this.pageNumber++;
            this.updatePage();
        }
    }

    prevPage() {
        if (this.pageNumber > 1) {
            this.pageNumber--;
            this.updatePage();
        }
    }

    get isFirstPage() {
        return this.pageNumber === 1;
    }

    get isLastPage() {
        return this.pageNumber === this.totalPages;
    }
}