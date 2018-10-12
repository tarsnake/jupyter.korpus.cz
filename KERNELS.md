# In general

Make sure that the `jupyter` installation you want to add the kernel to is the
first one on your path. Then everything should be hooked up as if by magic (?).
Although you'll probably have to move the kernel definition file from
`~/.local/share/jupyter/kernels` to `/opt/pyenv/.../share/jupyter/kernels`.

```sh
path/to/pip install ipykernel
path/to/python -m ipykernel install --prefix `pyenv prefix` --name my-kernel-name --display-name 'My human-readable kernel name'
```

# IPerl

```sh
# deps: apt install libzmq3-dev
cpanm Devel::IPerl
```

To make UTF8 work, add `"-Mutf8", "-Mopen qw(:std :encoding(UTF-8))",` to the
line containing `connection_file` in the `iperl` command-line wrapper.
(Ideally, you could add this in the `kernel.json` config file, but these keep
getting overwritten).

Also, in order for IPerl to work with JupyterLab, the `msg_kernel_info_request` subroutine might need to be patched
to send `busy` and `idle` notifications around its activities:

```perl
### DVL: import helper
use Devel::IPerl::Message::Helper;

sub msg_kernel_info_request {
	my ($self, $kernel, $msg ) = @_;

	### DVL: send kernel status : busy
	my $status_busy = Devel::IPerl::Message::Helper->kernel_status( $msg, 'busy' );
	$kernel->send_message( $kernel->iopub, $status_busy );

	my $reply = $msg->new_reply_to(
		msg_type => 'kernel_info_reply',
		content => {
			protocol_version => '5.0',
			implementation => 'iperl',
			implementation_version => $Devel::IPerl::VERSION // '0.0.0',
			language_info => {
				name => 'perl',
				version => substr($^V, 1), # 1 character past the 'v' prefix
				mimetype => 'text/x-perl',
				file_extension => '.pl',
			},
			banner => 'IPerl!',
			help_links => [
				{ text => 'MetaCPAN', url => 'https://metacpan.org/' },
				{ text => 'Perldoc', url => 'http://perldoc.perl.org/' },
				{ text => 'PDL', url => 'http://pdl.perl.org/?docs=Index&title=PDL::Index' },
			],
		}
	);
	$kernel->send_message( $kernel->shell, $reply );

	### DVL: send kernel status : idle
	my $status_idle = Devel::IPerl::Message::Helper->kernel_status( $msg, 'idle' );
	$kernel->send_message( $kernel->iopub, $status_idle );
}
```

See also patches as commits in <https://github.com/dlukes/p5-Devel-IPerl>.
