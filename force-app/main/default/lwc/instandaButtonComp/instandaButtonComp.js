import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from "lightning/navigation";
import { CloseActionScreenEvent } from 'lightning/actions';
import generateURL from '@salesforce/apex/InstandaButtonCompController.generateURL';
import generateURLLead2 from '@salesforce/apex/InstandaButtonCompController.generateURLLead2';

const LEAD_FIELDS = [
    'Lead.Product_Code__c',
    'Lead.Product_Type__c'
];

export default class InstandaButtonComp extends LightningElement {
    _recordId;
    objectApiName;
    actionButtonName;
    isSpinner = false;
    productCode;
    productType;
    isContextReady = false;
    isRecordReady = false;
    recordData;
    isRecordIdReady = false;

    @api set recordId(value) {
        this._recordId = value;
        this.isRecordIdReady = true;

        console.log('recordId set:', value);

        this.initialize();
    }
    get recordId() {
        return this._recordId;
    }

    get fields() {
        const fieldMap = {
            Lead: [
                'Lead.Product_Code__c',
                'Lead.Product_Type__c'
            ]
        };
    
        return fieldMap[this.objectApiName] || [];
    }

    @wire(getRecord, { recordId: '$_recordId', fields: '$fields' })
    wiredRecord({ error, data }) {

        if (data) {
            this.recordData = data;
            this.isRecordReady = true;
            this.initialize();
        } else if (error) {
            console.error(error);
            this.showToast('Error', 'Unable to load record data', 'error');
        }
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference?.type === "standard__quickAction") {
            const quickActionPath = currentPageReference.attributes.apiName;

            this.objectApiName = quickActionPath.split('.')[0];
            this.actionButtonName = quickActionPath.split('.')[1];

            console.log('objectApiName:', this.objectApiName);
            console.log('actionButtonName:', this.actionButtonName);

            this.isContextReady = true;
            this.initialize();
        }
    }

    initialize() {

        console.log('***record Id = ' + this._recordId);
        
        if (!this.isContextReady || !this.isRecordIdReady) {
            return;
        }
    
        if (this.fields.length === 0) {
            this.retrieveURL();
            return;
        }
    
        if (!this.isRecordReady) {
            return;
        }
    
        this.productCode = this.recordData.fields.Product_Code__c?.value || null;
        this.productType = this.recordData.fields.Product_Type__c?.value || null;
    
        this.retrieveURL();
    }

    get headerLabel(){
        if(this.objectApiName == 'Lead' && this.actionButtonName == 'Start_Instanda_Quote'){
            return 'Start Instanda Quote';
        } else {
            return 'Open Instanda Search';
        }
    }

    async retrieveURL(){
        try{
            this.isSpinner = true;

            // console.log('productCode: ' + this.productCode);
            // console.log('productType: ' + this.productType);

            if(this.objectApiName == 'Lead'){
                if (!this.productCode || !this.productType) {
                    this.showToast(
                        'Missing Information',
                        'Product Code and Product Type fields must be populated.',
                        'error'
                    );
    
                    setTimeout(() => {
                        this.isSpinner = false;
                        this.dispatchEvent(new CloseActionScreenEvent());
                    }, 1000);
                    return;
                }
            }

            let dataWrapper;

            if(this.objectApiName == 'Lead' && this.actionButtonName == 'Open_Instanda_Search' ){
                console.log('***LEAD');
                dataWrapper = await generateURLLead2({
                    recordId : this._recordId
                });
            }
            else{
                console.log('***OTHER');
                console.log('***this.objectApiName = ' + this.objectApiName);
                dataWrapper = await generateURL({
                    recordId : this._recordId,
                    objectAPIName : this.objectApiName
                });
            }

            console.log('***datawrapper = ' + JSON.stringify(dataWrapper));

            if(dataWrapper.dataToCopy != '' && dataWrapper.dataToCopy){
                if (navigator.clipboard && window.isSecureContext) {
                    await navigator.clipboard.writeText(dataWrapper.dataToCopy);
                } else {
                    let textArea = document.createElement("textarea");
                    textArea.value = dataWrapper.dataToCopy;
                    textArea.style.position = "absolute";
                    textArea.style.left = "-9999px";
                    document.body.appendChild(textArea);
                    textArea.select();
                    document.execCommand("copy");
                    document.body.removeChild(textArea);
                }
            }

            window.open(dataWrapper.generatedURL, '_blank'); 

            this.isSpinner = false;
            this.dispatchEvent(new CloseActionScreenEvent());
        }catch(error){
            console.error(error);
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant,
                mode: 'dismissable'
            })
        );
    }
}