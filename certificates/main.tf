resource "aws_acm_certificate" "oxycert" {
  private_key       = file("../letsencrypt/config/archive/oxycloud.space/privkey1.pem")
  certificate_body  = file("../letsencrypt/config/archive/oxycloud.space/cert1.pem")
  certificate_chain = file("../letsencrypt/config/archive/oxycloud.space/fullchain1.pem")
}

