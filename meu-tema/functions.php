<?php
function rest_scripts() {
    wp_register_style('rest-style', get_template_directory_uri() . '/style.css', array(), '1.0.0', 'all');
    wp_enqueue_style('rest-style');
}
add_action('wp_enqueue_scripts', 'rest_scripts');

// Habilitar menus
function rest_config() {
    register_nav_menus(
        array(
            'header-menu' => 'Menu Header'
        )
    );
}
add_action('after_setup_theme', 'rest_config');
