import LightningModal from 'lightning/modal';
import getAllProducts from '@salesforce/apex/ProductController.getAllProducts';

export default class ProductSelectorModal extends LightningModal {

    products = [];              // all products from Apex
    selectedProductIds = [];    // track selected rows

    async connectedCallback() {
        // Fetch products from Apex
        try {
            this.products = await getAllProducts();
            // Add qty property default 1
            this.products = this.products.map(p => ({ ...p, qty: 1 }));
        } catch (error) {
            console.error('Error loading products:', error);
        }
    }

    // Update quantity
    updateQty(e) {
        const id = e.target.dataset.id;
        const qty = parseInt(e.target.value, 10) || 1;

        this.products = this.products.map(p =>
            p.id === id ? { ...p, qty } : p
        );
    }

    // Confirm selection — send only selected products
    confirm() {
        // If you want to send all products, just use this.products
        // Otherwise filter only selected products
        const selected = this.products.filter(p => this.selectedProductIds.includes(p.id));
        this.close(selected.length ? selected : this.products);
    }

    // Handle row checkbox selection
    handleRowSelection(event) {
        this.selectedProductIds = event.detail.selectedRows.map(p => p.id);
    }

    // Close modal without returning
    closeModal() {
        this.close();
    }
}
