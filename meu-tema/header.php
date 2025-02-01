<!DOCTYPE html>
<html <?php language_attributes(); ?>>
	<head>
		<meta charset="utf-8">
		<title><?php bloginfo('name'); ?></title>

		<link href='https://fonts.googleapis.com/css?family=Alegreya+SC' rel='stylesheet' type='text/css'>
		<?php wp_head(); ?>
	</head>

	<body <?php body_class(); ?>>
		
		<header>
			<nav>
				<ul>
					<li class="current_page_item"><a href="<?php echo home_url('/'); ?>">Menu</a></li>
					<li><a href="<?php echo home_url('/sobre'); ?>">Sobre</a></li>
					<li><a href="<?php echo home_url('/contato'); ?>">Contato</a></li>
				</ul>
			</nav>

			<h1><img src="<?php echo get_template_directory_uri(); ?>/img/rest.png" alt="Rest"></h1>

			<p>Rua Marechal 29 – Copacabana – Rj</p>
			<p class="telefone">2422-9201</p>
		</header>