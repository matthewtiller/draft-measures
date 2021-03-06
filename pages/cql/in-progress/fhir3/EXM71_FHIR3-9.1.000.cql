library EXM71_FHIR3 version '9.1.000'

/*
Based on CMS71v9 - Anticoagulation Therapy for Atrial Fibrillation/Flutter
Author: TJC
*/

using FHIR version '3.0.0'

include FHIRHelpers version '3.0.0'
include MATGlobalCommonFunctions_FHIR3 version '4.0.000' called Global
include TJC_Overall_FHIR3 version '3.6.000' called TJC
include SupplementalDataElements_FHIR3 version '1.0.0' called SDE

codesystem "LOINC": 'http://loinc.org'

valueset "Anticoagulant Therapy": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.200'
valueset "Atrial Ablation": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.203'
valueset "Atrial Fibrillation/Flutter": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.202'
valueset "Comfort Measures": 'http://cts.nlm.nih.gov/fhir/ValueSet/1.3.6.1.4.1.33895.1.3.0.45'
valueset "Discharge To Acute Care Facility": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.87'
valueset "Discharged to Health Care Facility for Hospice Care": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.207'
valueset "Discharged to Home for Hospice Care": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.209'
valueset "Emergency Department Visit": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.292'
valueset "Ethnicity": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.114222.4.11.837'
valueset "Hemorrhagic Stroke": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.212'
valueset "Ischemic Stroke": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.247'
valueset "Left Against Medical Advice": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.308'
valueset "Medical Reason": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.473'
valueset "Non-Elective Inpatient Encounter": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.424'
valueset "Observation Services": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1111.143'
valueset "ONC Administrative Sex": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113762.1.4.1'
valueset "Patient Expired": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.309'
valueset "Patient Refusal": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.113883.3.117.1.7.1.93'
valueset "Payer": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.114222.4.11.3591'
valueset "Race": 'http://cts.nlm.nih.gov/fhir/ValueSet/2.16.840.1.114222.4.11.836'
context Patient

define "SDE Ethnicity":
  SDE."SDE Ethnicity"

define "SDE Payer":
	SDE."SDE Payer"

define "SDE Race":
  SDE."SDE Race"

define "SDE Sex":
	SDE."SDE Sex"

define "Reason for Not Giving Anticoagulant at Discharge":
	["MedicationRequest"] NoAnticoagulant
	 where (NoAnticoagulant.medication as CodeableConcept) in "Anticoagulant Therapy"
	 		and (singleton from NoAnticoagulant.reasonCode in "Medical Reason"
				or singleton from NoAnticoagulant.reasonCode in "Patient Refusal")

define "Anticoagulant Therapy at Discharge":
	["MedicationRequest": "Anticoagulant Therapy"]

define "Initial Population":
	TJC."Encounter with Principal Diagnosis and Age"

define "Encounter with Atrial Ablation Procedure":
	TJC."Ischemic Stroke Encounter" IschemicStrokeEncounter
		with ["Procedure": "Atrial Ablation"] AtrialAblation
			such that AtrialAblation.performed Period starts before start of IschemicStrokeEncounter.period

define "Numerator":
	"Denominator" Encounter
		with "Anticoagulant Therapy at Discharge" DischargeAnticoagulant
			such that DischargeAnticoagulant.authoredOn during Encounter.period

define "Current Diagnosis Atrial Fibrillation or Flutter":
	TJC."Ischemic Stroke Encounter" IschemicStrokeEncounter
		where exists ( IschemicStrokeEncounter.diagnoses Diagnosis
				where Diagnosis in "Atrial Fibrillation/Flutter"
		)

define "Denominator":
	"Encounter with Atrial Ablation Procedure"
		union "History of Atrial Fibrillation or Flutter"
		union "Current Diagnosis Atrial Fibrillation or Flutter"

define "Denominator Exceptions":
	"Denominator" Encounter
		with "Reason for Not Giving Anticoagulant at Discharge" NoDischargeAnticoagulant
			such that NoDischargeAnticoagulant.authoredOn during Encounter.period

define "History of Atrial Fibrillation or Flutter":
	TJC."Ischemic Stroke Encounter" IschemicStrokeEncounter
		with ["Condition": "Atrial Fibrillation/Flutter"] AtrialFibrillationFlutter
			such that AtrialFibrillationFlutter.onset as dateTime on or before
			end of IschemicStrokeEncounter.period

define "Denominator Exclusions":
	( "Denominator" Encounter
			where Encounter.hospitalization.dischargeDisposition in "Discharge To Acute Care Facility"
				or Encounter.hospitalization.dischargeDisposition in "Left Against Medical Advice"
				or Encounter.hospitalization.dischargeDisposition in "Patient Expired"
				or Encounter.hospitalization.dischargeDisposition in "Discharged to Home for Hospice Care"
				or Encounter.hospitalization.dischargeDisposition in "Discharged to Health Care Facility for Hospice Care"
	)
		union "Comfort Measures during Hospitalization"

define "Comfort Measures during Hospitalization":
	"Denominator" Encounter
		with TJC."Intervention Comfort Measures" ComfortMeasure
			such that Coalesce(ComfortMeasure.performed as dateTime, ComfortMeasure.authoredOn)during Global."HospitalizationWithObservation"(Encounter)
