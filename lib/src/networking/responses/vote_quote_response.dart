import 'package:keeta/src/networking/responses/certificate_content_response.dart';

class VoteQuoteResponse {
  const VoteQuoteResponse({required this.quote});

  factory VoteQuoteResponse.fromJson(final Map<String, dynamic> json) =>
      VoteQuoteResponse(
        quote: CertificateContentResponse.fromJson(
          json['quote'] as Map<String, dynamic>,
        ),
      );

  final CertificateContentResponse quote;
}
