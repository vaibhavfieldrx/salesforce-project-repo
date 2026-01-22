import { LightningElement, track } from 'lwc';
import ProductModal from 'c/productSelectorModal';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getProducts from '@salesforce/apex/ProductController.getProducts';

export default class NewOrderForm extends LightningElement {

    customerId;
    @track products = [];          // Products to display in table
    total = 0;
    discount = 0;
    paymentStatus = 'Pending';
    selectedProducts = [];         // Selected from modal

    // Handle customer selection
    handleCustomer(e) {
        this.customerId = e.detail;
    }

    // Handle products selected from ProductModal
    async handleProductsSelected(event) {
        const selected = event.detail;
        const productIds = selected.map(p => p.Id);

        try {
            // Call Apex to get actual Pricebook prices
            const priceData = await getProducts({ productIds });

            this.selectedProducts = selected.map(p => {
                const priceObj = priceData.find(r => r.id === p.Id);
                return {
                    id: p.Id,
                    name: p.Name,
                    price: priceObj ? priceObj.price : 0,
                    qty: 1
                };
            });

            // Update products displayed in table
            this.products = [...this.selectedProducts];
            this.calculateTotal();

        } catch (error) {
            console.error('Error fetching product prices', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to fetch product prices',
                    variant: 'error'
                })
            );
        }
    }

    // Open modal to select products
    async openProductModal() {
        const selectedProducts = await ProductModal.open({
            size: 'large'
        });

        if (selectedProducts && selectedProducts.length) {
            this.handleProductsSelected({ detail: selectedProducts });
        }
    }

    // Handle quantity change in table (optional)
    handleQtyChange(e) {
        const productId = e.target.dataset.id;
        const qty = parseInt(e.target.value, 10) || 1;
        this.products = this.products.map(p => {
            if (p.id === productId) p.qty = qty;
            return p;
        });
        this.calculateTotal();
    }

    // Calculate total amount
    calculateTotal() {
        this.total = this.products.reduce(
            (sum, p) => sum + (p.price * p.qty), 0
        );
    }

    // Create order (dummy)
    createOrder() {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Order created successfully',
                variant: 'success'
            })
        );
    }
}
