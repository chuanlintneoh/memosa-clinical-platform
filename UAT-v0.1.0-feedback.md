# BUGS

1. /Resolved [BUG] Study coordinator, create case page - words at top of page are cut off - SC (including edit case, diagnose case)
2. /Resolved [BUG] Some text gets cut off on diagnose case screen, e.g. gender field - SC (hide copy button for a lot of text fields)
3. /Resolved [BUG] App crash when tapping screen during searching case
4. /Resolved [BUG] Stability in case creation (backend error handling in AI inference service after timeout)
5. /Resolved [BUG] App crashes when tapping back when undiagnosed cases screen loading

# ENHANCEMENTS

1. /Resolved [ENHANCEMENT] Diagnose case - do not need to make all fields copy-able - SC (same item as previous resolved bug)
2. /Resolved [ENHANCEMENT] Should be able to enlarge image when reviewing - AN (edit case & diagnose case)
3. /Resolved [ENHANCEMENT] Add forgot password/change password function - SC. AN
4. /NA [ENHANCEMENT] Using existing email for account registration
5. /Resolved [ENHANCEMENT] Allow photo of consent form to be taken directly via the app as well as 6. uploaded - AN (create case + biopsy report in edit case)
6. /Resolved [ENHANCEMENT] Can highlight all the missed mandatory fields when trying to submit at once? Right now it is only highlighting some in red - SC,AN (create case + diagnose case)
7. /Resolved [ENHANCEMENT] Modernize all UI (login, register, forgot password, home, role-based screens)
8. /Resolved [ENHANCEMENT] Duration for risk habits cannot leave blank? What should be entered if it is 'No" risk habits. Disable the duration section if No is selected - SC,AN (risk habits + oral hygiene products)
9. /Resolved [ENHANCEMENT] Restrict ID number field when adding patient to allow numerical input only? For NRIC you can also validate for the number of values as it is standardised, you can also auto-derive DOB and age from NRIC - SC, AN (NRIC: numbers only, PPN: capital letters and numbers only, DOB: auto derive from first 6 numbers of NRIC)
10. /Resolved [ENHANCEMENT] Apply clinical diagnoses dropdown list
11. /Resolved [ENHANCEMENT] Duration is free text? Can it be restricted to [number] WEEKS/MONTHS/YEARS , WEEKS/MONTHS/YEARS can be dropdown - SC, AN
12. /Resolved [ENHANCEMENT] Have a dropdown for ethnicity with others option that allows for free text, I recall we asked for this to be string but in hindsight this seems to be easier - AN
13. /Resolved [ENHANCEMENT] Can we include reason for low quality? Can use the dropdown list - SC, AN (export bundle: spreadsheet format)
14. /Resolved [ENHANCEMENT] Password for user registration, ideally different for user type and user (admin manage invite code screen)
15. /Resolved [ENHANCEMENT] Suggest that there is a next button to move onto the next image among the nine images instead of checking the dropdown - AN (Replace submit button with next button when diagnosis of all images are incomplete)
16. [ENHANCEMENT] How would you search if you did not copy the case ID? - SC,AN
17. [ENHANCEMENT] Notification mechanism to developer when AI inference service is down
18. /Nofix [ENHANCEMENT] Is it possible to have save as draft for clinician diagnosis? - SC, AN
19. /Nofix [ENHANCEMENT] Case submission and export bundle takes a while - AN

## OTHERS

/Nofix [BUG] Cannot find cases after submission - SC (TBC)
/Nofix [BUG] Search not working - SC, AN [see screenshot] (TBC)
/Nofix [BUG] Could not test case editing, as cannot search cases after submitting because search not working - SC, AN (TBC)
/Nofix [BUG] I don't see the cases that I submitted with the study coordinator account. Am I supposed to? - SC,AN (TBC)
