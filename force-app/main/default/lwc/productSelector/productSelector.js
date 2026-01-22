import { LightningElement, wire, track } from 'lwc';
import getAllProducts from '@salesforce/apex/ProductController.getAllProducts';

export default class ProductSelector extends LightningElement {

    @track products = [];
    @track selectedProducts = [];
    selectedRowIds = [];
    @track showSelectedProducts = false;
    totalAmount = 0;

    columns = [
        { label: 'Product Name', fieldName: 'name' },
        { label: 'Product Code', fieldName: 'productCode' },
        { label: 'Description', fieldName: 'description' },
        { label: 'Family', fieldName: 'family' },
        { label: 'Price', fieldName: 'price', type: 'currency' }
    ];

    @wire(getAllProducts)
    wiredProducts({ data, error }) {
        if (data) {
            this.products = data.map(p => ({ ...p, qty: 1 }));
        } else if (error) {
            console.error('Error loading products:', error);
        }
    }

    handleRowSelection(event) {
        this.selectedProducts = event.detail.selectedRows.map(p => ({
            ...p,
            qty: p.qty || 1,
            subtotal: p.price * (p.qty || 1) // compute subtotal here
        }));
        this.selectedRowIds = this.selectedProducts.map(p => p.id);
    }

    handleAddSelected() {
        if (!this.selectedProducts.length) {
            alert('Please select at least one product.');
            return;
        }
        this.showSelectedProducts = true;
        this.calculateTotal();
    }

    handleQtyChange(event) {
        const id = event.target.dataset.id;
        const qty = parseInt(event.target.value, 10) || 1;

        this.selectedProducts = this.selectedProducts.map(p =>
            p.id === id ? { ...p, qty, subtotal: p.price * qty } : p
        );

        this.calculateTotal();
    }

    calculateTotal() {
        this.totalAmount = this.selectedProducts.reduce(
            (sum, p) => sum + p.subtotal, 0
        );
    }

    confirmSelection() {
        this.dispatchEvent(new CustomEvent('productsselected', {
            detail: this.selectedProducts
        }));
    }
}
