# Preview all emails at http://localhost:3000/rails/mailers/kgcash_mailer
class KgcashMailerPreview < ActionMailer::Preview
	def welcome_mail_preview
		KgcashMailer.welcome_email(User.first)
	end
end
