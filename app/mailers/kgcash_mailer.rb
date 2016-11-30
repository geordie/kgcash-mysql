class KgcashMailer < ApplicationMailer
	default from: "geordie.a.henderson@gmail.com"

	def welcome_email(user)
		@user = user
		mail(to: @user.email, subject: 'Wecome to KGCash!')
	end
end
