package notes_web;
use Dancer2;
use Dancer::Plugin::EscapeHTML;
use Dancer2::Plugin::Database;
use Dancer2::Plugin::CSRF;
use File::Slurper qw/read_text/;
use utf8;

our ($LOGIN, $PASSWORD, $NOTE) = ('/^[a-z][a-z0-9]{3,31}$/i', '/^\w{6,20}$/', '/^.{1,255}$/m');
our ($pLOGIN, $pPASSWORD, $pNOTE) = map {eval "qr$_"} ($LOGIN, $PASSWORD, $NOTE);

hook before => sub {
	if (request->is_post()) {
		my $csrf_token = param('token');
		if (!$csrf_token || !validate_csrf_token($csrf_token)) {
			redirect '/error?reason=bad_token';
		}
	}
};

get '/' => sub {
	if (my $login = session('login')) {
		database->do('set names utf8');
		my $sth = database->prepare("SELECT login FROM Users WHERE login != ?");
		$sth->execute($login);
		my $readers;
		map {$readers .= "<option>$_->{login}</option>"} @{$sth->fetchall_arrayref({})};
		template 'index' => {'readers' => $readers, 'note' => "maxlength=255 placeholder=\"$login, введи текст заметки(не более 255 символов)\"", 'token' => get_csrf_token()};
	} else {
		redirect '/login';
	}
};

get '/notes' => sub {
	if (my $login = session('login')) {
		database->do('set names utf8');
		my ($id, $sth) = (params->{id});
		unless (defined $id) {
			$sth = database->prepare("SELECT DISTINCT(id), note FROM Notes WHERE publisher = ?");
			$sth->execute($login);
			my $notes;
			map {my $s = length $_->{note} < 30 ? $_->{note} : substr($_->{note}, 0, 27) . "...";$notes .= "<option value=$_->{id}>$s</option>"} @{$sth->fetchall_arrayref({})};
			return template 'mynotes' => {'link' => $notes, 'token' => get_csrf_token()};
		}
		$sth = database->prepare("SELECT note FROM Notes WHERE id = ? AND (reader = ? or publisher = ?) LIMIT 1");
		$sth->execute($id, $login, $login);
		if (my $note = $sth->fetchall_arrayref({})->[0]{note}) {
			return $note if defined params->{ajax};
			template 'notes' => {'note' => escape_html($note), 'token' => get_csrf_token()};
		} else {
			status 404;
			eval {read_text('./public/404.html') or halt};
		}
	} else {
		redirect '/login';
	}
};

post '/notes' => sub {
	my $p = params->{readers};
	my @readers = ref $p eq "ARRAY" ? @{$p} : $p ? $p : ();
	if ((my $login = session('login')) =~ $pLOGIN && (my $note = params->{note}) =~ $pNOTE) {
		database->do('set names utf8');
		my $sth = database->prepare("SELECT login FROM Users WHERE login = ?");
		my %hash;
		map {$hash{$_} = "1" if ($_ =~ $pLOGIN && $sth->execute($_) && @{$sth->fetchall_arrayref})} @readers;
		$sth = database->prepare("SELECT MAX(id) FROM Notes");
		$sth->execute();
		my $id = ($sth->fetchall_arrayref()->[0]->[0] // 0) + 1;
		$sth = database->prepare("INSERT INTO Notes (id, publisher, note, reader) VALUES (?, ?, ?, ?)");		
		redirect "/notes" unless %hash;
		$sth->execute($id, $login, $note, $_) foreach (keys %hash);
		redirect "/notes?id=$id";
	} else {
		redirect '/error?reason=Login Failed';
	}
};

get '/login' => sub {
	template 'login' => {'login' => $LOGIN, 'password' => $PASSWORD, 'token' => get_csrf_token()};
};

post '/login' => sub {
	my $login = lc params->{login};
	my $password = params->{password};
	unless ($login =~ $pLOGIN or $password =~ $pPASSWORD) {
		redirect '/error?reason=Login Failed';
	}
	database->do('set names utf8');
	my $sth = database->prepare("SELECT password FROM Users WHERE login = ?");
	$sth->execute($login);
	my $user = $sth->fetchall_arrayref({});
	if ((@$user) and (params->{password} eq $user->[0]->{password})) {
		session 'login' => $user;
		redirect '/';
	} else {
		redirect '/error?reason=Login Failed';
	}
};

get '/logout' => sub {
	app->destroy_session;
	redirect '/login';
};

get '/register' => sub {
	template 'register' => {'login' => $LOGIN, 'password' => $PASSWORD, 'token' => get_csrf_token()};
};

post '/register' => sub {
	my $login = lc params->{login};
	my $password = params->{password};
	unless ($login =~ $pLOGIN or $password =~ $pPASSWORD) {
		redirect '/error?reason=Register Failed';
	}
	database->do('set names utf8');	
	my $sth = database->prepare("SELECT login FROM Users WHERE login = ?");
	$sth->execute($login);
	my $user = $sth->fetchall_arrayref();
	if (@$user) {
		redirect '/error?reason=Register Failed';
	}
	else {
		$sth = database->prepare("INSERT INTO Users (login, password) VALUES (?, ?)");
		$sth->execute($login, $password);
		session login => $login;
		redirect '/';
	}
};

get '/error' => sub {
	my $error = params->{reason};
	return template 'error' => {'error' => escape_html($error)} if $error;
	redirect '/';
};

true;
