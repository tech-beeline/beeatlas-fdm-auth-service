package ru.beeline.fdmauth.controller;

import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import ru.beeline.fdmauth.service.ProductService;

@CrossOrigin(origins = "*", allowedHeaders = "*")
@RestController
@RequestMapping("/api/product")
@Api(value = "Product API", tags = "Product")
public class ProductController {

    @Autowired
    private ProductService productService;


    @GetMapping("/{id}/existence")
    @ApiOperation(value = "Проверка существования продукта", response = Boolean.class)
    public ResponseEntity<Boolean> checkProductExistence(@PathVariable Long id) {
        return ResponseEntity.ok(productService.checkProductExistenceById(id));
    }

}