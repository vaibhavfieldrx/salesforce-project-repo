import { LightningElement, wire, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';

import ChartJS from '@salesforce/resourceUrl/ChartJS';

import getMonthlyOrderTrend
    from '@salesforce/apex/OrderTrendChartController.getMonthlyOrderTrend';

export default class OrderTrendChart extends LightningElement {

    chart;
    chartJsLoaded = false;

    // ✅ FIX: Make year STRING
    @track selectedYear = new Date().getFullYear().toString();

    chartData;


    // Year dropdown options
    get yearOptions() {

        const currentYear = new Date().getFullYear();

        return [
            {
                label: currentYear.toString(),
                value: currentYear.toString()
            },
            {
                label: (currentYear - 1).toString(),
                value: (currentYear - 1).toString()
            },
            {
                label: (currentYear - 2).toString(),
                value: (currentYear - 2).toString()
            }
        ];
    }


    // Fetch data when year changes
    @wire(getMonthlyOrderTrend, { year: '$selectedYear' })
    wiredTrend({ data, error }) {

        if (data) {

            this.chartData = data;

            this.renderChart();
        }

        if (error) {

            console.error('Apex Error:', error);
        }
    }


    // Load ChartJS
    renderedCallback() {

        if (this.chartJsLoaded) return;

        this.chartJsLoaded = true;

        loadScript(this, ChartJS)

            .then(() => {

                this.renderChart();
            })

            .catch(error => {

                console.error('ChartJS Load Error:', error);
            });
    }


    // Year change handler
    handleYearChange(event) {

        // ✅ Always string
        this.selectedYear = event.detail.value;
    }


    // Render Chart
    renderChart() {

        if (!this.chartJsLoaded || !this.chartData) return;


        const canvas =
            this.template.querySelector('[data-id="trendChart"]');

        if (!canvas) return;


        if (this.chart) {

            this.chart.destroy();
        }


        const ctx = canvas.getContext('2d');


        this.chart = new window.Chart(ctx, {

            type: 'line',

            data: {

                labels: this.chartData.map(item => item.label),

                datasets: [
                    {
                        data: this.chartData.map(item => item.value),

                        borderColor: '#2563eb',
                        backgroundColor: '#2563eb',

                        tension: 0.4,
                        pointRadius: 5,

                        fill: false
                    }
                ]
            },

            options: {

                responsive: true,
                maintainAspectRatio: false,

                plugins: {
                    legend: { display: false }
                },

                scales: {

                    y: {

                        beginAtZero: true,

                        ticks: {
                            stepSize: 50,
                            precision: 0
                        },

                        suggestedMax: 200
                    }
                }
            }
        });
    }
}