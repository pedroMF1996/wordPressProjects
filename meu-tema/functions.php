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

function cmb2_fields_home() {
    $cmb = new_cmb2_box([
        'id' => 'homeBox',
        'title' => 'Home',
        'object_types' => ['page'],
        'show_on' => [
            'key' => 'page-template',
            'value' => 'page-home.php'
        ]
    ]);

    $cmb->add_field([
        'id' => 'comida',
        'name' => 'Comida',
        'type' => 'text'
    ]);

    $cmb->add_field([
        'id' => 'descricao',
        'name' => 'Descrição',
        'type' => 'textarea'
    ]);

    $comidas = $cmb->add_field([
        'name'=>'Pratos',
        'id'=>'pratos',
        'type' => 'group',
        'reapeatable' => true,
        'options'=>[
            'group_title'=>'Prato {#}',
            'add_button'=>'Adicionar Prato',
            'sortable'=>true
        ]
    ]);
    
    $cmb->add_group_field($comidas, [
        'id'=>'nome',
        'name'=>'Nome',
        'type'=>'text'
    ]);

    $cmb->add_group_field($comidas, [
        'id'=>'descricao',
        'name'=>'Descrição',
        'type'=>'textarea',
    ]);

    $cmb->add_group_field($comidas, [
        'id'=>'preco',
        'name'=>'Preço',
        'type'=>'text',
    ]);
}

add_action('cmb2_admin_init', 'cmb2_fields_home');

function cmb2_fields_sobre() {
    $cmb = new_cmb2_box([
        'id' => 'sobreBox',
        'title' => 'Sobre',
        'object_types' => ['page'],
        'show_on' => [
            'key' => 'page-template',
            'value' => 'page-sobre.php'
        ]
    ]);
    
    $cmb->add_field([
        'name'=>'Foto Rest',
        'id'=>'fotoRest',
        'type'=>'file',
        'options'=>[
            'url'=>false
            ]
        ]);
}
add_action('cmb2_admin_init', 'cmb2_fields_sobre');

function get_field($key, $page_id = 0){
    $id = $page_id !== 0 ? $page_id : get_the_ID();
    return get_post_meta($id, $key, true);
}

function the_field($key, $page_id = 0){
    echo get_field($key, $page_id);
}
?>