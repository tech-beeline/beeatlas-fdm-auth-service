package ru.beeline.fdmauth.controller;

import io.swagger.annotations.Api;
import io.swagger.annotations.ApiOperation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import ru.beeline.fdmauth.domain.Product;
import ru.beeline.fdmauth.dto.bw.EmployeeProductsDTO;
import ru.beeline.fdmauth.service.ProductService;
import ru.beeline.fdmauth.service.BWEmployeeService;
import java.util.List;

@CrossOrigin(origins = "*", allowedHeaders = "*")
@RestController
@RequestMapping("/api/user")
@Api(value = "Product API", tags = "Product")
public class ProductController {

    @Autowired
    private ProductService productService;

    @Autowired
    private BWEmployeeService bwEmployeeService;

    @GetMapping("/product")
    @ApiOperation(value = "Получение списка продуктов", response = List.class)
    public ResponseEntity<List<Product>> getProducts(@RequestHeader("Authorization") String bearerToken) {
        return ResponseEntity.ok(productService.findProductsByPermission(bearerToken));
    }

    @GetMapping("/bw/products/{login}")
    @ApiOperation(value = "Получение списка продуктов из BeeWorks по логину пользователя", response = EmployeeProductsDTO.class)
    public EmployeeProductsDTO getEmployeeProducts(@PathVariable String login) {
        return bwEmployeeService.getEmployeeInfo(login);
    }

}