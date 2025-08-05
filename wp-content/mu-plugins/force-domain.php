<?php
/**
 * Plugin Name: Force Domain (MU)
 * Description: Força siteurl/home a partir de WP_FORCE_DOMAIN (prioritário) ou RAILWAY_PUBLIC_DOMAIN.
 * Must-Use plugin: carregado automaticamente antes dos plugins comuns.
 */

if (!function_exists('fd_env_domain_value')) {
   function fd_env_domain_value($default)
   {
      // 1) Lê variáveis de ambiente
      $d = getenv('WP_FORCE_DOMAIN');
      if (!$d) {
         $d = getenv('RAILWAY_PUBLIC_DOMAIN');
      }
      if (!$d) {
         return $default; // sem domínio, mantém o que vier do banco
      }

      $d = trim($d);

      // 2) Se vier URL completa (https://meusite.com/...), reduz para somente host
      if (preg_match('#^https?://#i', $d)) {
         $p = parse_url($d);
         if (!empty($p['host'])) {
            $d = $p['host'];
         } else {
            return $default; // URL inválida, não força
         }
      }

      // 3) Remove barras à esquerda/direita por segurança
      $d = preg_replace('#^/+|/+$#', '', $d);

      // 4) Retorna a URL final padronizada
      return 'https://' . $d;
   }

   add_filter('pre_option_siteurl', 'fd_env_domain_value', 1, 1);
   add_filter('pre_option_home', 'fd_env_domain_value', 1, 1);
}
