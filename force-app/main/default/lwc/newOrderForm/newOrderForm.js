import { LightningElement, track } from 'lwc';
import ProductModal from 'c/productSelectorModal';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getProducts from '@salesforce/apex/ProductController.getProducts';
import createOrderWithItems from '@salesforce/apex/OrderController.createOrderWithItems';


export default class NewOrderForm extends LightningElement {

    customerId;
    @track products = [];          // Products to display in table
    total = 0;
    discount = 0;
    paymentStatus = 'Pending';
    selectedProducts = [];         // Selected from modal

    // Handle customer selection
handleCustomer(event) {
    this.selectedCustomer = event.detail; // ✅ object
    this.customerId = event.detail.accountId; // ✅ ONLY Id
}

    // Handle products selected from ProductModal

    async handleProductsSelected(event) {

           const { products, totalAmount, paymentStatus  } = event.detail;
        console.log("event.detail", products)

           if (!Array.isArray(products)) {
        console.error('❌ products is not an array', products);
        return;
    }
    
    this.orderProducts = products;
    this.orderTotal = totalAmount;
    this.paymentStatus = paymentStatus;

    console.log('Products:', JSON.stringify(this.orderProducts));
    console.log('Total:', this.orderTotal);
    
        try {
              const productIds = products.map(p => p.productId);
            // Call Apex to get actual Pricebook prices
            const priceData = await getProducts({ productIds });

            this.selectedProducts = products.map(p => {
                const priceObj = priceData.find(r => r.id === p.Id);
                return {
                    id: p.productId,
                    name: p.Name,
                    price: priceObj ? priceObj.price : p.unitPrice,
                    qty: p.quantity
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
        // const type = event.target.dataset.type;   // billing / shipping
        // const field = event.target.dataset.field;
        // const value = event.target.value;

        // this[type] = {
        //     ...this[type],
        //     [field]: value
        // };

        const { billingAddress, shippingAddress, warehouseId } = event.detail;
    this.orderAddressData = {
        billingAddress,
        shippingAddress,
        warehouseId
    };

    }


    // Create order (dummy)
     @track otpRequired = false;
     @track showOtpModal = false;

    handleOtpRequiredChange(event) {
        this.otpRequired = event.target.checked;
    }



    handleCreateOrder() {
        if (this.otpRequired) {
           this.showOtpModal = true; // show modal
        } else {
            this.createOrder();
        }
    }

    handleVerifyOtp(event) {
    const otp = event.detail.otp;

    console.log('OTP received from child:', otp);

    // Close modal
    this.showOtpModal = false;

    // ✅ Parent owns order creation
    this.createOrder();
}

handleCloseOtp() {
    this.showOtpModal = false;
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


    createOrderWithItems({ orderJson: JSON.stringify(finalOrderPayload) })
    .then(orderId => {
        console.log('✅ Order Created:', orderId);
    })
    .catch(error => {
        console.error('❌ Order Error:', error.body?.message);
    });

    }

  

}
