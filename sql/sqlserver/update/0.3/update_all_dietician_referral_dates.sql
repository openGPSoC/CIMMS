Update nutrition_management
Set dietitian_referral_time = time_screened
where date_screened < dietitian_referral_date
and dietitian_referral_time < time_screened


Update nutrition_management
Set dietitian_referral_date = date_screened
where date_screened < dietitian_referral_date