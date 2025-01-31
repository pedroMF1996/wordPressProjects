<?php get_header(); ?>
<section class="container sobre">
    <?php 
        if(have_posts()) : while (have_posts()) : the_post();
    ?>
        <h2 class="subtitulo"><?php the_title(); ?></h2>
        <div class="grid-8">
            <?php the_content(); ?>
        </div>
    <?php endwhile; else : ?>
        <p>Nenhum post encontrado</p>
    <?php endif; ?>
</section>

<?php get_footer(); ?>