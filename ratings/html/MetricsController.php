<?php

declare(strict_types=1);

namespace Instana\RobotShop\Ratings\Controller;

use Prometheus\CollectorRegistry;
use Prometheus\Storage\APC;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;

/**
 * Exposes ratings' Prometheus metrics.
 *
 * Uses APCu as the storage backend rather than in-memory, since each PHP
 * request under Apache/mod_php starts with a blank process memory space —
 * a plain in-memory counter (like cart/payment use in Node/Python) would
 * reset to zero on every single request here. APCu is shared memory across
 * Apache's worker processes on the same node, which is what makes counts
 * actually accumulate correctly.
 */
class MetricsController
{
    /**
     * @Route("/metrics", methods={"GET"})
     */
    public function metrics(): Response
    {
        $registry = new CollectorRegistry(new APC());

        $renderer = new \Prometheus\RenderTextFormat();
        $result = $renderer->render($registry->getMetricFamilySamples());

        return new Response($result, 200, ['Content-Type' => \Prometheus\RenderTextFormat::MIME_TYPE]);
    }
}
