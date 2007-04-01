package WebService::30Boxes::API;

use strict;
use Carp qw/croak/;
use WebService::30Boxes::API::Request;
use WebService::30Boxes::API::Response;
use LWP::UserAgent;
use XML::Simple;

our $VERSION = '0.01';

sub new {
   my ($class, %params) = @_;

   my $self = bless ({}, ref ($class) || $class);
   unless($params{'api_key'}) {
       croak "You need to set your API key before launching a request.\n".
             "See http://30boxes.com/api/api.php?method=getKeyForUser";
   }
   $self->{'_apiKey'} = $params{'api_key'};
   $self->{'_ua'}     = LWP::UserAgent->new(
      'agent' => __PACKAGE__."/".$VERSION,
   );

   return $self;
}

sub call {
   my ($self, $meth, $args) = @_;

   croak "No method specified." unless(defined $meth);

   my $req = WebService::30Boxes::API::Request->new($meth, $args);
   if(defined $req) { 
      unless(defined $self->{'_apiKey'}) {
      }
      $req->{'_api_args'}->{'apiKey'} = $self->{'_apiKey'};
      $req->encode_args();
      $self->_execute($req);
   } else {
      return;
   }
}

sub request_auth_url {
   my ($self, $args) = @_;
   for my $c (qw/applicationName applicationLogoUrl/) {
      croak "$c is not defined." unless(defined $args->{$c});
   }

   my $req = WebService::30Boxes::API::Request->new('user.Authorize', $args);
      $req->{'_api_args'}->{'apiKey'} = $self->{'_apiKey'};
      $req->encode_args();
   return $req->uri .'?'. $req->content; 
}

sub _execute {
   my ($self, $req) = @_;
   
   my $resp = $self->{'_ua'}->request($req);
   bless $resp, 'WebService::30Boxes::API::Response';

   if($resp->{'_rc'} != 200){
      $resp->set_error(0, "API returned a non-200 status code ".
                          "($resp->{'_rc'})");
      return $resp;
   }

   my $result = $resp->reply(XML::Simple::XMLin($resp->{'_content'}, 
                             ForceArray => 0));
   if(!defined $result->{'stat'}) {
      $resp->set_error(0, "API returned an invalid response");
      return $resp;
   }

   if($result->{'stat'} eq 'fail') {
      $resp->set_error($result->{err}{code}, $result->{err}{msg});
      return $resp;
   }

   $resp->set_success();

   return $resp; 
}

#################### main pod documentation begin ###################

=head1 NAME

WebService::30Boxes::API - Perl interface to the 30boxes.com REST API

=head1 SYNOPSIS

  use WebService::30Boxes::API;

  # You always have to provide your api_key
  my $boxes  = WebService::30Boxes::API->(api_key => 'your_api_key');

  # Then you might want to lookup a user and print some info
  my $result = $boxes->call('user.FindById', { id => 47 });
  if($result->{'success'}) {
     my $user   = $result->reply->{'user'};
  
     print $user->{'firstName'}, " ",
           $user->{'lastName'}, " joined 30Boxes at ",
           $user->{'createDate'},"\n";
  } else {
     print "An error occured ($result->{'error_code'}: ".
           "$result->{'error_msg'})";
  }
  
  # If authorization is needed, you need to get permission first:
  my $redirect = $boxes->request_auth_url({
     applicationName    => '30Boxes cool application',
     applicationLogoUrl => 'http://wherever/your/logo/is-stored.png',
     returnUrl          => 'http://wherever/you/want/the/client_to_return/'
  }); 
  
  print CGI::redirect($redirect);

  # After that, you may call the 'call' method as described above

=head1 DESCRIPTION

C<WebService::30Boxes::API> - Perl interface to the 30boxes.com REST API

=head2 METHODS

The following methods can be used

=head3 new

C<new> create a new C<WebService::30Boxes::API> object

=head4 options

=over 5

=item api_key

The API key is B<required> and this module will croak if you do not set one
here. A fresh key can be obtained at L<http://30boxes.com/api/api.php?method=getKeyForUser>

=back

=head3 call

With this method, you can call one of the available methods as described
on L<http://30boxes.com/api/>. 

C<call> accepts a method name followed by a hashref with the values to
pass on to 30Boxes. It returns a L<WebService::30Boxes::API::Response>
object.

=head3 request_auth_url

Some API methods require authentication (permission by the user). This
is done by sending the user to a specific URL where permission can be granted
or denied. This method accepts a hashref with these three values:

=over 5

=item applicationName

(B<Mandatory>) applicationName sets the well, application name you want to
show to the user.

=item applicationLogoUrl

(B<Mandatory>) The URI to your logo.

=item returnUrl

(B<Optional>) This is where you want the user to return too after permission
is granted.

=back

=head1 SEE ALSO

L<http://30boxes.com/>, L<http://30boxes.com/api/>

L<WebService::30Boxes::API::Response>

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/Ticket/Create.html?Queue=WebService::30Boxes::API>.

=head1 AUTHOR

M. Blom, 
E<lt>blom@cpan.orgE<gt>,
L<http://menno.b10m.net/perl/>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
