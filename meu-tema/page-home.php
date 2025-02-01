<?php
// Template Name: Menu da Semana
?>

<?php get_header(); ?>
	<?php if ( have_posts() ) : while ( have_posts() ) : the_post(); ?>
		<section class="container">
			<h2 class="subtitulo"><?php the_title(); ?></h2>

			<div class="menu-item grid-8">
				<!-- <h2><?php echo get_post_meta(get_the_ID(), 'comida', true)?></h2> -->
				<h2><?php the_field('comida')?></h2>
				<ul>
					<?php
						$pratos = get_field('pratos');
						if (isset($pratos)){
							foreach ($pratos as $prato){
					?>
					<li>
						<span><sup>R$</sup><?php echo $prato['preco'] ?></span>
						<div>
							<h3><?php echo $prato['nome'] ?></h3>
							<p><?php echo $prato['descricao'] ?></p>
						</div>
					</li>
					<?php 
							}
						}
					?>
				</ul>
			</div>

			<div class="menu-item grid-8">
				<h2>Carnes</h2>
				<ul>
					<li>
						<span><sup>R$</sup>129</span>
						<div>
							<h3>Picanha Nobre no Alho</h3>
							<p>Pequenas tiras de salmão feitas no alho e óleo</p>
						</div>
					</li>
					<li>
						<span><sup>R$</sup>89</span>
						<div>
							<h3>Cupim no Bafo</h3>
							<p>Sardinhas escolhidas a dedo e fritas em cerveja premium</p>
						</div>
					</li>
					<li>
						<span><sup>R$</sup>159</span>
						<div>
							<h3>Hamburger Artesanal Rest</h3>
							<p>Grandes camarões grelhados, servidos ao molho de camarão com catupiry</p>
						</div>
					</li>
				</ul>
			</div>

		</section>
	<?php endwhile; else : endif; ?>
<?php get_footer(); ?>