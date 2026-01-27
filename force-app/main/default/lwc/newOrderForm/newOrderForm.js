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
        console.log("www", e.detail)
        this.customerId = e.detail;
    }

    // Handle products selected from ProductModal
    async handleProductsSelected(event) {
        const selected = event.detail;
        const productIds = selected.map(p => p.Id);

           const { products, totalAmount, paymentStatus, addresschange, customerselect  } = event.detail;

    this.orderProducts = products;
    this.orderTotal = totalAmount;
    this.paymentStatus = paymentStatus;
    this.orderAddressData = addresschange;
    this.selectedCustomer = customerselect;

    console.log('Products:', JSON.stringify(this.orderProducts));
    console.log('Total:', this.orderTotal);
    
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

     handleAddressChange(event) {
        const type = event.target.dataset.type;   // billing / shipping
        const field = event.target.dataset.field;
        const value = event.target.value;

        this[type] = {
            ...this[type],
            [field]: value
        };

        this.notifyParent();
    }


    // Create order (dummy)
     @track otpRequired = false;

    handleOtpRequiredChange(event) {
        this.otpRequired = event.target.checked;
    }

    handleOtpVerify(event) {
    console.log('OTP Verified:', event.detail.otp);
    this.createOrder(); // ✅ NOW create order
}

    handleCreateOrder() {
        const productComp = this.template.querySelector('c-product-selector');

        // if (this.otpRequired) {
        //     productComp.openOtpModal(); // show modal
        // } else {
            this.createOrder();
        // }
    }

    // Optional: handle OTP verified event from child
    handleOtpVerify(event) {
        console.log('OTP Verified in parent', event.detail);
        // Call order creation API if needed
    }

    createOrder(){
//   if (!this.selectedCustomer?.accountId) {
//         alert('Select customer first');
//         return;
//     }

//     if (!this.orderProducts?.length) {
//         alert('Select at least one product');
//         return;
//     }

console.log("thhh", this.selectedCustomer, this.orderAddressData)
    const finalOrderPayload = {
        accountId: this.selectedCustomer.accountId,
        billToContactId: this.selectedCustomer.contactId,

        billingAddress: this.orderAddressData.billingAddress,
        shippingAddress: this.orderAddressData.shippingAddress,

        warehouseId: this.orderAddressData.warehouseId,

        paymentStatus: this.paymentStatus,
        totalAmount: this.orderTotal,

        products: this.orderProducts
    };

    console.log('FINAL PAYLOAD → ', JSON.stringify(finalOrderPayload));

    createOrderWithItems({ orderData: finalOrderPayload })
        .then(orderId => {
            console.log('Order Created:', orderId);
        })
        .catch(error => {
            console.error(error);
        });

    }

    verifyAndCreateOrder() {
    if (this.otp.length === 6) {
        this.showOtpModal = false;
        this.createOrder();

        // Notify parent
        const event = new CustomEvent('verifyotp', { detail: this.otp });
        this.dispatchEvent(event);
    } else {
        alert('Enter complete 6-digit OTP.');
    }
}

}
