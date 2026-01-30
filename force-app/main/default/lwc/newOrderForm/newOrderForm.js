import { LightningElement, track, wire } from 'lwc';
import ProductModal from 'c/productSelectorModal';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getProducts from '@salesforce/apex/ProductController.getProducts';
import createOrderWithItems from '@salesforce/apex/OrderController.createOrderWithItems';
import getOrderHistory from '@salesforce/apex/OrderController.getOrderHistory';
import { NavigationMixin } from 'lightning/navigation';
import LightningAlert from 'lightning/alert';
export default class NewOrderForm  extends NavigationMixin(LightningElement) {

    customerId;
    @track products = [];
    total = 0;
    discount = 0;
    paymentStatus = 'Pending';
    selectedProducts = [];
    @track orders = [];
    @track totalRecords = 0;
    @track pageNumber = 1;
    @track pages = []; // for pagination {number, class}
    pageSize = 5;
    isLoading = false;
    @track otpRequired = false;
    @track showOtpModal = false;
    orderAddressData = {};
    orderProducts = [];
    orderTotal = 0;
    selectedCustomer;

    // Pagination getters
    get totalPages() {
        return Math.ceil(this.totalRecords / this.pageSize) || 1;
    }

    get isFirstPage() {
        return this.pageNumber === 1;
    }

    get isLastPage() {
        return this.pageNumber === this.totalPages;
    }

    // Wire order history
    @wire(getOrderHistory, { 
        accountId: '$customerId',
        pageSize: '$pageSize',
        pageNumber: '$pageNumber'
    })
    wiredOrders({ data, error }) {
        this.isLoading = false;
        if (data) {
            this.orders = data.orders.map(order => ({
                ...order,
                statusClass: this.computeStatusClass(order.Status)
            }));
            this.totalRecords = data.totalRecords;
            this.updatePages();
        } else if (error) {
            console.error(error);
            this.orders = [];
            this.totalRecords = 0;
        }
    }

    // Compute status class
    computeStatusClass(status) {
        switch ((status || '').toLowerCase()) {
            case 'draft':
                return 'status-draft';
            case 'completed':
                return 'status-completed';
            case 'cancelled':
                return 'status-cancelled';
            case 'pending':
                return 'status-pending';
            default:
                return 'status-default';
        }
    }

    // Update pagination pages array
    updatePages() {
        this.pages = Array.from({ length: this.totalPages }, (_, i) => {
            const number = i + 1;
            return {
                number,
                class: number === this.pageNumber ? 'page active' : 'page'
            };
        });
    }

    // Customer selection
    handleCustomer(event) {
        this.selectedCustomer = event.detail;
        this.customerId = event.detail.accountId;
        if (this.customerId) {
            this.pageNumber = 1;
            this.isLoading = true;
        }
    }

      async showAlert(title, message, theme) {
        await LightningAlert.open({
            message: message,
            theme: theme, // success | error | warning | info
            label: title
        });
    }

    // Pagination handlers
    handleNext() {
        if (!this.isLastPage) {
            this.pageNumber += 1;
            this.isLoading = true;
        }
    }

    handlePrev() {
        if (!this.isFirstPage) {
            this.pageNumber -= 1;
            this.isLoading = true;
        }
    }

    goToPage(event) {
        const page = parseInt(event.target.dataset.page, 10);
        this.pageNumber = page;
        this.isLoading = true;
    }

    handlePageSizeChange(event) {
        this.pageSize = parseInt(event.detail.value, 10);
        this.pageNumber = 1;
        this.isLoading = true;
    }

    get hasOrders() {
        return this.orders && this.orders.length > 0;
    }

    // Products selection
    async handleProductsSelected(event) {
        const { products, totalAmount, paymentStatus } = event.detail;

        if (!Array.isArray(products)) {
            console.error('❌ products is not an array', products);
            return;
        }

        this.orderProducts = products;
        this.orderTotal = totalAmount;
        this.paymentStatus = paymentStatus;

        try {
            const productIds = products.map(p => p.productId);
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

    async openProductModal() {
        const selectedProducts = await ProductModal.open({ size: 'large' });
        if (selectedProducts && selectedProducts.length) {
            this.handleProductsSelected({ detail: selectedProducts });
        }
    }

    handleQtyChange(e) {
        const productId = e.target.dataset.id;
        const qty = parseInt(e.target.value, 10) || 1;
        this.products = this.products.map(p => {
            if (p.id === productId) p.qty = qty;
            return p;
        });
        this.calculateTotal();
    }

    openOrderModal() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
             attributes: {
                url: '/order'
            }
        });
    }

    calculateTotal() {
        this.total = this.products.reduce((sum, p) => sum + (p.price * p.qty), 0);
    }

    handleAddressChange(event) {
        const { billingAddress, shippingAddress, warehouseId } = event.detail;
        this.orderAddressData = { billingAddress, shippingAddress, warehouseId };
    }

    handleOtpRequiredChange(event) {
        this.otpRequired = event.target.checked;
    }

    handleCreateOrder() {
        if (this.otpRequired) {
            this.showOtpModal = true;
        } else {
            this.createOrder();
        }
    }

    handleVerifyOtp(event) {
        const otp = event.detail.otp;
        console.log('OTP received:', otp);
        this.showOtpModal = false;
        this.createOrder();
    }

    handleCloseOtp() {
        this.showOtpModal = false;
    }


    async showSuccessAndReload() {
    await LightningAlert.open({
        message: 'Order Created Successfully',
        theme: 'success',
        label: 'Success'
    });

    // ✅ User clicked OK
    window.location.reload();
}

    createOrder() {
        if (!this.selectedCustomer?.accountId) {
            this.showAlert(
            'Error',
            'Select a customer first',
            'error'
        );
            
            return;
        }

        if (!this.orderProducts?.length) {
               this.showAlert(
            'Error',
            'Select at least one product',
            'error'
        );

           
            return;
        }

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
               this.showSuccessAndReload();
            })
            .catch(error => {
                console.error('❌ Order Error:', error.body?.message);
                  this.showAlert(
            'Error',
            error?.body?.message || 'Order creation failed',
            'error'
        );
                // this.dispatchEvent(
                //     new ShowToastEvent({ title: 'Error', message: error.body?.message || 'Order creation failed', variant: 'error' })
                // );
            });
    }
}
